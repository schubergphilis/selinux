require 'chef/mixin/params_validate'
define :selinux_rule do

  ::Chef::Recipe.send(:include, Chef::Mixin::ParamsValidate)

  # Defaults
  params[:action] ||= :create
  params[:allow] ||= ""
  params[:comment] ||= ""

  # Validation
  validate(
    { :allow => params[:allow] },
    { :kind_of => [ String, Array ] }
  )

  validate(
    { :comment => params[:comment] },
    { :kind_of => String }
  )

  allowed_actions = [:create, :remove]
  validate(
    { :action => params[:action] },
    { :kind_of => [ Symbol ],
      :equal_to => allowed_actions}
  )

  # obj = SELinux::Rule.new(params[:name],params[:rule])
  case params[:allow]
    when String
      SELinux::Rule.new(params[:name],params[:allow],params[:comment])
    when Array
      params[:allow].each do |r|
        SELinux::Rule.new(params[:name],r,params[:comment])
      end
  end

end
