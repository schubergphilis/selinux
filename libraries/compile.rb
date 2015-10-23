require 'chef/provider/lwrp_base'
require 'chef/resource/lwrp_base'

# Backwards compatibility
class Chef
  class Resource::SelinuxCompile < Resource::LWRPBase
    self.resource_name = 'selinux_compile'
    actions :compile

    state_attrs :runner,
                :from_file,
                :seperate_files,
                :version,
                :se_dir,
                :se_file,
                :delayed

    attribute :runner, :kind_of => String, :required => true, :name_attribute => true
    attribute :from_file, :kind_of => [TrueClass, FalseClass], :default => false
    attribute :seperate_files, :kind_of => [TrueClass, FalseClass], :default => false
    attribute :version, :kind_of => Float, :default => 1.0
    attribute :se_dir, :kind_of => String, :default => "/etc/selinux/local/selinux_rules.te"
    attribute :se_file, :kind_of => String, :required => true
    attribute :delayed, :kind_of => [TrueClass, FalseClass], :default => false

    def initialize(*args)
      super
      @action = :compile
      # Set some default values
      @resource_name = :selinux_compile
      @provider = Provider::SelinuxCompile
      @runner = runner
      @from_file = from_file
      @seperate_files = seperate_files
      @version = version
      @se_dir = se_dir
      @se_file = se_file
    end

    def delayed(arg = nil)
      if arg == true
        @delayed = true
      elsif @delayed == false
        r = dup
        r.delayed(true)
        @run_context.resource_collection << r
      end
      @delayed
    end
  end

  class Provider::SelinuxCompile < Provider::LWRPBase
    def whyrun_supported?
      true
    end

    action :compile do

      # If there are rules to create
      if SELinux.instance.types.length > 0

        if new_resource.from_file
          # Compile file provided
        elsif new_resource.seperate_files
          # Create seperate files per App
        else
          # Create single file for all rukes defined

          # create_te_file(new_resource.se_dir, new_resource.se_file, new_resource.runner, new_resource.version, true)
      else
        Chef::Log.info "No SELinux rules found, no need to compile"
      end

    end

    private

    def create_te_file(dir, file, runner, version, create=true)
      directory dir do
        owner 'root'
        group 'root'
        recursive true
        mode 0755
      end

      template "#{dir}/#{file}" do
        source 'selinux_rules.erb'
        cookbook 'selinux'
        variables(
          :recipe_file => (__FILE__).to_s.split('cookbooks/').last,
          :template_file => source.to_s,
          :name => runner,
          :version => version,
          :types => SELinux.instance.types,
          :classes => SELinux.instance.classes,
          :rules => SELinux.instance.rules
        )
        notifies :run, 'execute[selinux_policy_install]', :immediately
      end

      module_name = "#{dir}/#{file.sub(/\.te$/,'')}"

      execute 'selinux_policy_install' do
        command "/usr/bin/checkmodule -m -M -o #{module_name}.mod #{module_name}.te && /usr/bin/semodule_package -o #{module_name}.pp -m #{module_name}.mod && /usr/sbin/semodule -i #{module_name}.pp"
        action :nothing
      end
    end

  end
end
