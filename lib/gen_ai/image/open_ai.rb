# frozen_string_literal: true

module GenAI
  class Image
    class OpenAI < Base
      DEFAULT_SIZE = '256x256'
      DEFAULT_MODEL = 'dall-e-3'
      RESPONSE_FORMAT = 'b64_json'

      def initialize(token:, options: {})
        depends_on 'ruby-openai'

        @client = ::OpenAI::Client.new(access_token: token)
      end

      def generate(prompt, options = {})
        parameters = build_generation_options(prompt, options)

        response = handle_errors { @client.images.generate(parameters: parameters) }

        build_result(
          raw: response,
          model: parameters[:model],
          parsed: response['data'].map { |datum| datum[RESPONSE_FORMAT] }
        )
      end

      def variations(image, options = {})
        parameters = build_variations_options(image, options)

        response = handle_errors { @client.images.variations(parameters: parameters) }

        build_result(
          raw: response,
          model: 'dall-e',
          parsed: response['data'].map { |datum| datum[RESPONSE_FORMAT] }
        )
      end

      def edit(image, prompt, options = {})
        parameters = build_edit_options(image, prompt, options)

        response = handle_errors { @client.images.edit(parameters: parameters) }

        build_result(
          raw: response,
          model: 'dall-e',
          parsed: response['data'].map { |datum| datum[RESPONSE_FORMAT] }
        )
      end

      private

      def build_generation_options(prompt, options)
        {
          prompt: prompt,
          size: options.delete(:size) || DEFAULT_SIZE,
          model: options.delete(:model) || DEFAULT_MODEL,
          response_format: options.delete(:response_format) || RESPONSE_FORMAT
        }.merge(options)
      end

      def build_variations_options(image, options)
        {
          image: image,
          size: options.delete(:size) || DEFAULT_SIZE,
          response_format: options.delete(:response_format) || RESPONSE_FORMAT
        }.merge(options)
      end

      def build_edit_options(image, prompt, options)
        {
          image: image,
          prompt: prompt,
          size: options.delete(:size) || DEFAULT_SIZE,
          response_format: options.delete(:response_format) || RESPONSE_FORMAT
        }.merge(options)
      end
    end
  end
end
