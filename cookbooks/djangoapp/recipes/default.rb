include_recipe 'apt'
include_recipe 'build-essential'
# include_recipe 'openssl'
include_recipe 'postgresql::server'
include_recipe 'git'

include_recipe 'database::postgresql'
include_recipe 'python'

user "#{node[:owner]}" do
    gid "#{node[:group]}"
    home "#{node[:ownerhome]}"
    shell "/bin/bash"
end

directory "#{node[:ownerhome]}" do
    owner "#{node[:owner]}"
    group "#{node[:group]}"
    mode 0775
end

# create a postgresql database
postgresql_database "#{node[:dbname]}" do
  connection(
    :host      => '127.0.0.1',
    :port      => 5432,
    :username  => 'postgres',
    :password  => node['postgresql']['password']['postgres']
  )
  action :create
end

directory "#{node[:ownerhome]}/envs" do
    owner "#{node[:owner]}"
    group "#{node[:group]}"
    mode 0775
end

virtualenv_dir = "#{node[:ownerhome]}/envs/#{node[:virtualenv_name]}"

virtualenv virtualenv_dir do
    owner "#{node[:owner]}"
    group "#{node[:group]}"
    options "--system-site-packages"
    mode 0775
end

if node["target"] == "production"
    directory "#{node[:project_dir]}" do
        owner "#{node[:owner]}"
        group "#{node[:group]}"
        mode 0775
    end

    git "#{node[:project_dir]}" do
        repository "https://github.com/beholderrk/djangotests.git"
        reference "HEAD"
        user "#{node[:owner]}"
        group "#{node[:group]}"
        action :sync
        notifies :restart, "service[#{node[:gunicorn][:project_name]}-gunicorn]", :delayed
        notifies :restart, "service[celeryd]", :delayed
        notifies :restart, "service[celeryflower]", :delayed
    end
end

execute 'install-requirements' do
    command "pip install -r #{node[:project_dir]}/requirements.txt -E #{virtualenv_dir}"
    not_if "pip freeze -E #{virtualenv_dir} | grep django"
end

if node["target"] == "production"
    template "#{node[:project_dir]}/djangotests/local_settings.py" do
        source "local_settings.py"
        owner "#{node[:owner]}"
        group "#{node[:group]}"
        mode 0644
    end
end

activate_env = "source #{virtualenv_dir}/bin/activate"
to_project = "cd #{node[:project_dir]}"

bash 'syncdb' do
    code <<-EOH
#{activate_env}
#{to_project}
python manage.py syncdb --noinput
python manage.py createsuperuser <<EOF
#{node[:django][:admin][:login]}
#{node[:django][:admin][:email]}
#{node[:django][:admin][:pass]}
#{node[:django][:admin][:pass]}
EOF
EOH
    not_if "sudo -u postgres psql -d #{node[:dbname]} -c 'select * from auth_user' | grep #{node[:django][:admin][:login]}"
end

template "#{node[:project_dir]}/start_gunicorn.sh" do
    source "start_gunicorn.sh"
    owner "#{node[:owner]}"
    group "#{node[:group]}"
    mode 0755
end

directory "#{node[:gunicorn][:log_root]}" do
    owner "#{node[:owner]}"
    group "#{node[:group]}"
    mode 0775
end

template "/etc/init/#{node[:gunicorn][:project_name]}-gunicorn.conf" do
    source "gunicorn.conf"
    owner "root"
    group "root"
    mode 0644
end

service "#{node[:gunicorn][:project_name]}-gunicorn" do
    provider Chef::Provider::Service::Upstart
    enabled true
    running true
    supports :restart => true, :reload => true, :status => true
    action [:enable, :start]
end

if node["target"] == "production"
    package "nginx" do
        action :install
    end

    file "/etc/nginx/sites-available/default" do
        action :delete
    end

    file "/etc/nginx/sites-enabled/default" do
        action :delete
    end

    template "/etc/nginx/sites-available/#{node[:nginx][:server_name]}.conf" do
        source "nginx/#{node[:nginx][:server_name]}.conf"
        mode 0640
        owner "root"
        group "root"
        # notifies :restart, resources(:service => "nginx")
    end

    link "/etc/nginx/sites-enabled/#{node[:nginx][:server_name]}.conf" do
        to "/etc/nginx/sites-available/#{node[:nginx][:server_name]}.conf"
    end

    template "/etc/nginx/nginx.conf" do
        source "nginx/nginx.conf"
        mode 0640
        owner "root"
        group "root"
        # notifies :restart, resources(:service => "nginx")
    end

    service "nginx" do
        enabled true
        running true
        supports :status => true, :restart => true, :reload => true
        action [:start, :enable]
    end

    directory "#{node[:static_root]}" do
        owner "#{node[:owner]}"
        group "#{node[:group]}"
        mode 0775
    end

    bash 'collectstatic' do
        user "#{node[:owner]}"
        code <<-EOH
            #{activate_env}
            #{to_project}
            python manage.py collectstatic --noinput
        EOH
    end
end

package "rabbitmq-server" do
    action :install
end

template "/etc/default/celeryd" do
    source "celeryd.conf"
    owner "root"
    group "root"
    mode 0644
end

cookbook_file "/etc/init.d/celeryd" do
    source "celeryd"
    owner "root"
    group "root"
    mode 0755
end

service "celeryd" do
    enabled true
    running true
    supports :status => true, :restart => true, :reload => true
    action [:start, :enable]
end

# bash 'celery' do
#     user "root"
#     group "root"
#     code "sudo /etc/init.d/celeryd restart"
#     not_if "ps ax | grep 'celery worker -A #{node[:gunicorn][:project_name]}' | grep -v grep"
# end

template "#{node[:project_dir]}/start_celeryflower.sh" do 
    source "start_celeryflower.sh"
    owner "#{node[:owner]}"
    group "#{node[:group]}"
    mode 0755
end

template "/etc/init/celeryflower.conf" do
    source "celeryflower.conf"
    owner "root"
    group "root"
    mode 0644
end

bash "enable_rmq_managment" do
    user "root"
    code "/usr/lib/rabbitmq/lib/rabbitmq_server-2.7.1/sbin/rabbitmq-plugins enable rabbitmq_management"
    not_if "/usr/lib/rabbitmq/lib/rabbitmq_server-2.7.1/sbin/rabbitmq-plugins list -E | grep rabbitmq_management"
end

service "celeryflower" do
    provider Chef::Provider::Service::Upstart
    enabled true
    running true
    supports :status => true, :restart => true, :reload => true
    action [:start, :enable]
end

