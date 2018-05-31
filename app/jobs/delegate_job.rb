class DelegateJob < ApplicationJob
  queue_as :delegate

  def perform(class_name, method, *args, **options)
    klass = ::Object.const_get(class_name)
    options.blank? ? klass.send(method, *args) : klass.send(method, *args, **options)
  end
end
