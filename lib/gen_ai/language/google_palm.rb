# frozen_string_literal: true

module GenAI
  class Language
    class GooglePalm < Base
      DEFAULT_ROLE = '0'
      EMBEDDING_MODEL = 'textembedding-gecko-001'
      COMPLETION_MODEL = 'text-bison-001'
      CHAT_COMPLETION_MODEL = 'chat-bison-001'

      def initialize(token:, options: {})
        depends_on 'google_palm_api'

        @provider = :google_palm
        @client = ::GooglePalmApi::Client.new(api_key: token)
      end

      def embed(input, model: nil)
        responses = array_wrap(input).map do |text|
          handle_errors { client.embed(text: text, model: model) }
        end

        GenAI::Result.new(
          provider: @provider,
          model: EMBEDDING_MODEL,
          raw: { 'data' => responses, 'usage' => {} },
          values: responses.map { |response| response.dig('embedding', 'value') }
        )
      end

      def complete(prompt, options: {})
        parameters = build_completion_options(prompt, options)

        response = handle_errors { client.generate_text(**parameters) }

        GenAI::Result.new(
          provider: @provider,
          model: parameters[:model],
          raw: response.merge('usage' => {}),
          values: response['candidates'].map { |candidate| candidate['output'] }
        )
      end

      def chat(message, context: nil, history: [], examples: [], options: {})
        response = handle_errors do
          client.generate_chat_message(**build_chat_options(message, context, history, examples, options))
        end

        response['candidates']
      end

      private

      def build_chat_options(message, context, history, examples, options)
        {
          model: options.delete(:model) || CHAT_COMPLETION_MODEL,
          messages: history.append({ author: DEFAULT_ROLE, content: message }),
          examples: compose_examples(examples),
          context: context
        }.merge(options)
      end

      def build_completion_options(prompt, options)
        {
          prompt: prompt,
          model: options.delete(:model) || COMPLETION_MODEL
        }.merge(options)
      end

      def compose_examples(examples)
        examples.each_slice(2).map do |example|
          {
            input: { content: symbolize(example.first)[:content] },
            output: { content: symbolize(example.last)[:content] }
          }
        end
      end

      def symbolize(hash)
        hash.transform_keys(&:to_sym)
      end

      def array_wrap(object)
        return [] if object.nil?

        object.respond_to?(:to_ary) ? object.to_ary || [object] : [object]
      end
    end
  end
end
