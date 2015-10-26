require 'chef/provider/lwrp_base'
require 'chef/resource/lwrp_base'

# Backwards compatibility
class Chef
  class Resource::SelinuxModule < Resource::LWRPBase
    self.resource_name = 'selinux_compile'
    actions :create, :compile

    state_attrs :runner,
                :version,
                :source,
                :destination_dir,
                :use_seperate_files,
                :delayed

    attribute :runner, :kind_of => String, :required => true, :name_attribute => true
    attribute :version, :kind_of => Float, :default => 1.0
    attribute :source, :kind_of => String, :default => nil
    attribute :destination_dir, :kind_of => String, :default => '/etc/selinux/local'
    attribute :use_seperate_files, :kind_of => [TrueClass, FalseClass], :default => false
    attribute :delayed, :kind_of => [TrueClass, FalseClass], :default => false

    def initialize(*args)
      super
      @action = :compile
      # Set some default values
      @resource_name = :selinux_module
      @provider = Provider::SelinuxModule
      @runner = runner
      @version = version
      @source = source
      @destination_dir = destination_dir
      @use_seperate_files = use_seperate_files
      @te_filename = "selinux_rules.te"
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

  class Provider::SelinuxModule < Provider::LWRPBase

    use_inline_resources

    def whyrun_supported?
      true
    end

    include Chef::Mixin::ShellOut

    action :create do

      # If there are rules to create
      if SELinux.instance.types.length > 0

        if not (new_resource.source.nil? or
                new_resource.source.length = 0)
          # Compile file provided
          cf = Chef::Resource::CookbookFile.new("copy_te_file_#{new_resource.source}")
          cf.source(new_resource.source)
          cf.path(new_resource.destination_directory)
          cf.owner('root')
          cf.group('root')
          cf.mode(0644)
          cf.run_action(:create)

          if cf.updated_by_last_action?
            compile_te_file("#{new_resource.destination_directory}/#{new_resource.source}")
          else
            Chef::Log.info("SELinux: File #{new_resource.destination_directory}/#{new_resource.source} is up to date")
          end
        elsif new_resource.seperate_files
          # Create seperate files per App
          create_te_file(new_resource.destination_dir,
                         new_resource.te_filename,
                         new_resource.runner,
                         new_resource.version,
                         SELinux.instance.types,
                         SELinux.instance.classes,
                         SELinux.instance.rules,
                         true)
        else
          # Create single file for all rukes defined
          create_te_file(new_resource.destination_dir,
                         new_resource.te_filename,
                         new_resource.runner,
                         new_resource.version,
                         SELinux.instance.types,
                         SELinux.instance.classes,
                         SELinux.instance.rules,
                         true)
          # create_te_file(new_resource.se_dir, new_resource.se_file, new_resource.runner, new_resource.version, true)
      else
        Chef::Log.info "No SELinux rules found, no need to compile"
      end

    end

    private

    def compile_te_file(fn) do
      module_name = "#{new_resource.destination_directory}/#{file.sub(/\.te$/,'')}"
      shell_out!("/usr/bin/checkmodule -m -M -o #{module_name}.mod #{module_name}.te && /usr/bin/semodule_package -o #{module_name}.pp -m #{module_name}.mod && /usr/sbin/semodule -i #{module_name}.pp")
    end

    def create_te_file(dir, file, runner, version, types, classes, rules, create?=true)
      directory dir do
        owner 'root'
        group 'root'
        recursive true
        mode 0755
      end

      t = Chef::Resource::Template.new("create_te_file_#{dir}/#{file}"
      t.sourcer('selinux_rules.erb')
      t.cookbook('selinux')
      t.variables(
          :recipe_file => (__FILE__).to_s.split('cookbooks/').last,
          :template_file => source.to_s,
          :name => runner,
          :version => version,
          :types => types,
          :classes => classes,
          :rules => rules
        )
      t.run_action(:create)

      if t.updated_by_last_action?
          compile_te_file("#{dir}/#{file}")
      end
    end

  end
end
