package "python" do
  action :install
end

package "python-setuptools" do
  action :install
end

package "python-dev" do
  action :install
end

package "python-pip" do
  action :install
end

package "python-virtualenv" do
  action :install
end

# for Pillow
package "libjpeg-dev" do
    action :install
end

package "libpng12-dev" do
    action :install
end

package "libfreetype6-dev" do
    action :install
end