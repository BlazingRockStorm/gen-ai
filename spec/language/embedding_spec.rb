# frozen_string_literal: true

RSpec.describe GenAI::Language do
  describe '#embed' do
    let(:instance) { described_class.new(provider, token) }
    let(:token) { ENV['API_ACCESS_TOKEN'] || 'FAKE_TOKEN' }

    subject { instance.embed(input) }

    context 'with openai provider' do
      let(:provider) { :openai }

      context 'with single string input' do
        let(:input) { 'Hello' }
        let(:cassette) { 'openai/embed/single_input' }

        it 'returns an array with one embeddings' do
          VCR.use_cassette(cassette) do
            expect(subject).to be_a(GenAI::Result)

            expect(subject.provider).to eq(:openai)
            expect(subject.model).to eq('text-embedding-ada-002')

            expect(subject.value).to be_a(Array)
            expect(subject.value.size).to eq(1536)
            expect(subject.value).to all(be_a(Float))

            expect(subject.values).to be_a(Array)
            expect(subject.values.size).to eq(1)

            expect(subject.prompt_tokens).to eq(1)
            expect(subject.completion_tokens).to eq(0)
            expect(subject.total_tokens).to eq(1)
          end
        end

        context 'with custom model' do
          let(:input) { 'Hello' }
          let(:model) { 'text-similarity-davinci-001' }
          let(:cassette) { "openai/embed/single_input_#{model}" }

          subject { instance.embed(input, model: model) }

          it 'returns an array with one embeddings' do
            VCR.use_cassette(cassette) do
              expect(subject).to be_a(GenAI::Result)

              expect(subject.model).to eq('text-similarity-davinci-001')

              expect(subject.value.size).to eq(12_288)
              expect(subject.value).to all(be_a(Float))
            end
          end
        end
      end

      context 'with array input' do
        let(:input) { %w[Hello Cześć] }
        let(:cassette) { 'openai/embed/multiple_input' }

        it 'returns an array with two embeddings' do
          VCR.use_cassette(cassette) do
            expect(subject).to be_a(GenAI::Result)

            expect(subject.values[0]).to all(be_a(Float))
            expect(subject.values[0].size).to eq(1536)

            expect(subject.values[1]).to all(be_a(Float))
            expect(subject.values[1].size).to eq(1536)
          end
        end
      end

      context 'invalid input' do
        let(:input) { nil }
        let(:cassette) { 'openai/embed/invalid_input' }

        it 'raises an API error' do
          VCR.use_cassette(cassette) do
            expect { subject }.to raise_error(GenAI::ApiError, /Please submit an `input`/)
          end
        end
      end
    end

    context 'with google_palm provider' do
      let(:provider) { :google_palm }

      context 'with singe string input' do
        let(:input) { 'Hello' }
        let(:cassette) { 'google/embed/single_input' }

        it 'returns an array with one embeddings' do
          VCR.use_cassette(cassette) do
            expect(subject).to be_a(GenAI::Result)

            expect(subject.provider).to eq(:google_palm)

            expect(subject.model).to eq('textembedding-gecko-001')

            expect(subject.value.size).to eq(768)
            expect(subject.value).to all(be_a(Float))

            expect(subject.values.size).to eq(1)

            expect(subject.prompt_tokens).to eq(nil)
            expect(subject.completion_tokens).to eq(nil)
            expect(subject.total_tokens).to eq(nil)
          end
        end

        context 'with custom model' do
          let(:input) { 'Hello' }
          let(:model) { 'textembedding-gecko-multilingual' }
          let(:cassette) { "google/embed/single_input_#{model}" }

          subject { instance.embed(input, model: model) }

          it 'returns an array with one embeddings' do
            VCR.use_cassette(cassette) do
              expect do
                subject
              end.to raise_error(GenAI::ApiError,
                                 %r{GooglePalm API error: models/textembedding-gecko-multilingual is not found for API version v1beta2})
            end
          end
        end
      end

      context 'with array input' do
        let(:input) { %w[Hello Cześć] }
        let(:cassette) { 'google/embed/multiple_input' }

        it 'returns an array with two embeddings' do
          VCR.use_cassette(cassette) do
            expect(subject).to be_a(GenAI::Result)

            expect(subject.values[0]).to all(be_a(Float))
            expect(subject.values[0].size).to eq(768)

            expect(subject.values[1]).to all(be_a(Float))
            expect(subject.values[1].size).to eq(768)
          end
        end
      end

      context 'invalid input' do
        let(:input) { {} }
        let(:cassette) { 'google/embed/invalid_input' }

        it 'raises an GenAI::ApiError error' do
          VCR.use_cassette(cassette) do
            expect { subject }.to raise_error(GenAI::ApiError, /GooglePalm API error: Invalid value \(text\)/)
          end
        end
      end
    end

    context 'with unsupported provider' do
      let(:input) { 'Hello' }
      let(:provider) { :monster_ai }

      it 'raises an GenAI::UnsupportedProvider error' do
        expect { subject }.to raise_error(GenAI::UnsupportedProvider, /Unsupported LLM provider 'monster_ai'/)
      end
    end
  end
end
