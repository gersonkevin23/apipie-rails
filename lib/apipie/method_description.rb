require 'set'
module Apipie

  class MethodDescription

    class Api

      attr_accessor :short_description, :path, :http_method

      def initialize(method, path, desc)
        @http_method = method.to_s
        @path = path
        @short_description = desc
      end

    end

    attr_reader :full_description, :method, :resource, :apis, :examples, :see, :formats

    def initialize(method, resource, app, dsl_data)
      @method = method.to_s
      @resource = resource

      @apis = dsl_data[:api_args]
      @see = dsl_data[:see]
      @formats = dsl_data[:formats]

      desc = dsl_data[:description] || ''
      @full_description = Apipie.markup_to_html(desc)
      @errors = dsl_data[:errors]
      @params_ordered = dsl_data[:params]
      @examples = dsl_data[:examples]

      @examples += load_recorded_examples

      parent = @resource.controller.superclass
      if parent != ActionController::Base
        @parent_resource = parent.controller_name
      end
    end

    def id
      "#{resource._id}##{method}"
    end

    def params
      params_ordered.reduce(ActiveSupport::OrderedHash.new) { |h,p| h[p.name] = p; h }
    end

    def params_ordered
      all_params = []
      # get params from parent resource description
      if @parent_resource
        parent = Apipie.get_resource_description(@parent_resource)
        merge_params(all_params, parent._params_ordered) if parent
      end

      # get params from actual resource description
      if @resource
        merge_params(all_params, resource._params_ordered)
      end

      merge_params(all_params, @params_ordered)
      all_params.find_all(&:validator)
    end

    def errors
      return @merged_errors if @merged_errors
      @merged_errors = []
      if @resource
        # exclude overwritten parent errors
        @merged_errors = @resource._errors_ordered.find_all do |err|
          !@errors.any? { |e| e.code == err.code }
        end
      end
      @merged_errors.concat(@errors)
      return @merged_errors
    end

    def version
      resource._version
    end

    def doc_url
      crumbs = []
      crumbs << @resource._version if Apipie.configuration.version_in_url
      crumbs << @resource._id
      crumbs << @method
      Apipie.full_url crumbs.join('/')
    end

    def create_api_url(api)
      path = "#{Apipie.api_base_url(@resource._version)}#{api.path}"
      path = path[0..-2] if path[-1..-1] == '/'
      return path
    end

    def method_apis_to_json
      @apis.each.collect do |api|
        {
          :api_url => create_api_url(api),
          :http_method => api.http_method.to_s,
          :short_description => api.short_description
        }
      end
    end

    def see
      @see
    end

    def formats
      @formats || @resource._formats
    end

    def to_json
      {
        :doc_url => doc_url,
        :name => @method,
        :apis => method_apis_to_json,
        :formats => formats,
        :full_description => @full_description,
        :errors => errors.map(&:to_json),
        :params => params_ordered.map(&:to_json).flatten,
        :examples => @examples,
        :see => see.map(&:to_json)
      }
    end

    private

    def merge_params(params, new_params)
      new_param_names = Set.new(new_params.map(&:name))
      params.delete_if { |p| new_param_names.include?(p.name) }
      params.concat(new_params)
    end

    def load_recorded_examples
      (Apipie.recorded_examples[id] || []).
        find_all { |ex| ex["show_in_doc"].to_i > 0 }.
        find_all { |ex| ex["versions"].nil? || ex["versions"].include?(self.version) }.
        sort_by { |ex| ex["show_in_doc"] }.
        map { |ex| format_example(ex.symbolize_keys) }
    end

    def format_example_data(data)
      case data
      when Array, Hash
        JSON.pretty_generate(data).gsub(/: \[\s*\]/,": []").gsub(/\{\s*\}/,"{}")
      else
        data
      end
    end

    def format_example(ex)
      example = "#{ex[:verb]} #{ex[:path]}"
      example << "?#{ex[:query]}" unless ex[:query].blank?
      example << "\n" << format_example_data(ex[:request_data]).to_s if ex[:request_data]
      example << "\n" << ex[:code].to_s
      example << "\n" << format_example_data(ex[:response_data]).to_s if ex[:response_data]
      example
    end

  end

end
