# frozen_string_literal: true

RSpec.describe RuboCop::Rule::MessageAnnotator do
  let(:options) { {} }
  let(:config) { RuboCop::Config.new({}) }
  let(:rule_name) { 'Rule/Rule' }
  let(:annotator) do
    described_class.new(config, rule_name, config[rule_name], options)
  end

  describe '#annotate' do
    subject(:annotate) do
      annotator.annotate('message')
    end

    context 'with default options' do
      it 'returns the message' do
        expect(annotate).to eq('message')
      end
    end

    context 'when the output format is JSON' do
      let(:options) do
        {
          format: 'json'
        }
      end

      it 'returns the message unannotated' do
        expect(annotate).to eq('message')
      end
    end

    context 'with options on' do
      let(:options) do
        {
          extra_details: true,
          display_rule_names: true,
          display_style_guide: true
        }
      end
      let(:config) do
        RuboCop::Config.new(
          'Rule/Rule' => {
            'Details' => 'my cop details',
            'StyleGuide' => 'http://example.org/styleguide'
          }
        )
      end

      it 'returns an annotated message' do
        expect(annotate).to eq(
          'Rule/Rule: message my cop details (http://example.org/styleguide)'
        )
      end
    end
  end

  describe 'with style guide url' do
    subject(:annotate) do
      annotator.annotate('')
    end

    let(:rule_name) { 'Rule/Rule' }
    let(:options) do
      {
        display_style_guide: true
      }
    end

    context 'when StyleGuide is not set in the config' do
      let(:config) { RuboCop::Config.new({}) }

      it 'does not add style guide url' do
        expect(annotate).to eq('')
      end
    end

    context 'when StyleGuide is set in the config' do
      let(:config) do
        RuboCop::Config.new(
          'Rule/Rule' => { 'StyleGuide' => 'http://example.org/styleguide' }
        )
      end

      it 'adds style guide url' do
        expect(annotate).to include('http://example.org/styleguide')
      end
    end

    context 'when a base URL is specified' do
      let(:config) do
        RuboCop::Config.new(
          'AllRules' => {
            'StyleGuideBaseURL' => 'http://example.org/styleguide'
          }
        )
      end

      it 'does not specify a URL if a cop does not have one' do
        config['Rule/Rule'] = { 'StyleGuide' => nil }
        expect(annotate).to eq('')
      end

      it 'combines correctly with a target-based setting' do
        config['Rule/Rule'] = { 'StyleGuide' => '#target_based_url' }
        expect(annotate).to include('http://example.org/styleguide#target_based_url')
      end

      context 'when a department other than AllRules is specified' do
        let(:config) do
          RuboCop::Config.new(
            'AllRules' => {
              'StyleGuideBaseURL' => 'http://example.org/styleguide'
            },
            'Foo' => {
              'StyleGuideBaseURL' => 'http://foo.example.org'
            }
          )
        end

        let(:rule_name) { 'Foo/Rule' }
        let(:urls) { annotator.urls }

        it 'returns style guide url when it is specified' do
          config['Foo/Rule'] = { 'StyleGuide' => '#target_style_guide' }

          expect(urls).to eq(%w[http://foo.example.org#target_style_guide])
        end
      end

      it 'can use a path-based setting' do
        config['Rule/Rule'] = { 'StyleGuide' => 'cop/path/rule#target_based_url' }
        expect(annotate).to include('http://example.org/cop/path/rule#target_based_url')
      end

      it 'can accept relative paths if base has a full path' do
        config['AllRules'] = {
          'StyleGuideBaseURL' => 'https://github.com/rubocop-hq/ruby-style-guide/'
        }
        config['Rule/Rule'] = {
          'StyleGuide' => '../rails-style-guide#target_based_url'
        }
        expect(annotate).to include('https://github.com/rubocop-hq/rails-style-guide#target_based_url')
      end

      it 'allows absolute URLs in the cop config' do
        config['Rule/Rule'] = { 'StyleGuide' => 'http://other.org#absolute_url' }
        expect(annotate).to include('http://other.org#absolute_url')
      end
    end
  end

  describe '#urls' do
    let(:urls) { annotator.urls }
    let(:config) do
      RuboCop::Config.new(
        'AllRules' => {
          'StyleGuideBaseURL' => 'http://example.org/styleguide'
        }
      )
    end

    it 'returns an empty array without StyleGuide URL' do
      expect(urls.empty?).to be(true)
    end

    it 'returns style guide url when it is specified' do
      config['Rule/Rule'] = { 'StyleGuide' => '#target_based_url' }
      expect(urls).to eq(%w[http://example.org/styleguide#target_based_url])
    end

    it 'returns reference url when it is specified' do
      config['Rule/Rule'] = {
        'Reference' => 'https://example.com/some_style_guide'
      }
      expect(urls).to eq(%w[https://example.com/some_style_guide])
    end

    it 'returns an empty array if the reference url is blank' do
      config['Rule/Rule'] = {
        'Reference' => ''
      }

      expect(urls.empty?).to be(true)
    end

    it 'returns multiple reference urls' do
      config['Rule/Rule'] = {
        'Reference' => ['https://example.com/some_style_guide',
                        'https://example.com/some_other_guide',
                        '']
      }

      expect(urls).to eq(['https://example.com/some_style_guide',
                          'https://example.com/some_other_guide'])
    end

    it 'returns style guide and reference url when they are specified' do
      config['Rule/Rule'] = {
        'StyleGuide' => '#target_based_url',
        'Reference' => 'https://example.com/some_style_guide'
      }
      expect(urls).to eq(%w[http://example.org/styleguide#target_based_url
                            https://example.com/some_style_guide])
    end
  end
end
