class SELinux
  #
  # SELinux class
  #
  attr_reader :name
  attr_accessor :rules,
                :types,
                :classes

  def initialize
    @rules = {}
    @types = []
    @classes = {}
  end

  def self.instance
    @instance ||= SELinux.new
  end

  def push(name,rule,comment,source_t,target_t,class_name,perm_set)
    @rules[name] ||= {}
    @rules[name][comment] ||= {}
    key = "#{source_t}::#{target_t}::#{class_name}"
    push_item(key,@rules[name][comment],perm_set)
    push_item(source_t,types)
    push_item(target_t,types)
    push_item(class_name,classes,perm_set)
  end

  class Rule
    attr_reader :name,
                :rule,
                :comment

    def initialize(name,rule,comment)
      @name = name
      @rule = rule
      @comment = comment
      source_t,target_t,class_name,perm_set=parse_rule(@rule)
      SELinux.instance.push(@name,@rule,@comment,source_t,target_t,class_name,perm_set)
    end

    def to_s
      @name
    end

    private

    def parse_rule(rule)
      parsed = []
      parsed = rule.sub(/:/,' ').sub(/;$/,'').sub(/{ /,'').sub(/ }$/,'').split(' ')
      source_t = parsed[0]
      target_t = parsed[1]
      class_name = parsed[2]
      if parsed.count == 4
        perm_set = ''
        perm_set = parsed[3]
      else
        perm_set = []
        parsed[3..parsed.count-1].each do |perm|
          perm_set << perm
        end
      end
      return source_t,target_t,class_name,perm_set
    end
  end

  private

  def set_merge_permissions(permission)
    result_array = []
    if permission.respond_to?('push')
      permission.each do |perm|
        result_array.push(perm) unless result_array.include?(perm)
      end
    else
      result_array.push(permission) unless result_array.include?(permission)
    end
    result_array
  end

  def push_item(item,hash_or_array,value=nil)
    # Initialize array
    values=[]

    # If value argument is provided merge it into array
    unless value.nil?
      values = set_merge_permissions(value)
    end

    # If it is an array, push item into array if it does not exist
    if hash_or_array.respond_to?('push')
      hash_or_array.push(item.to_s) unless hash_or_array.include?(item.to_s)
    else
      # It is a Hash so if it does not exists, push it into hash and assign "value" if provided
      if hash_or_array[item.to_s].nil?
        hash_or_array[item.to_s] = value.nil? ? true : values
      else
        # If there was that key inserted before, merge value array items
        values.each do |v|
          if hash_or_array[item.to_s].include?(v)
            Chef::Log.debug("SELinux debug: #{item} is already defined")
          else
            hash_or_array[item.to_s].push(v)
          end
        end
      end
    end
  end
end
