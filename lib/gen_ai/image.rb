# frozen_string_literal: true

module GenAI
  class Image
    def initialize(provider, token, options: {})
      build_client(provider, token, options)
    end

    def generate(prompt, options = {})
      client.generate(prompt, options)
    end

    def variations(image, options = {})
      client.variations(image, options)
    end

    def edit(image, prompt, options = {})
      client.edit(image, prompt, options)
    end

    # def upscale; end

    private

    attr_reader :client

    def build_client(provider, token, options)
      klass = GenAI::Image.constants.find do |const|
        const.to_s.downcase == provider.to_s.downcase.gsub('_', '')
      end

      raise UnsupportedProvider, "Unsupported Image provider '#{provider}'" unless klass

      @client = GenAI::Image.const_get(klass).new(token: token, options: options)
    end
  end
end
