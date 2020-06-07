# frozen_string_literal: true

require 'support/file_helper'

RSpec.shared_context 'cli spec behavior' do
  include_context 'mock console output'

  include FileHelper

  def abs(path)
    File.expand_path(path)
  end

  before do
    RuboCop::ConfigLoader.debug = false
    RuboCop::ConfigLoader.default_configuration = nil

    # OPTIMIZE: Makes these specs faster. Work directory (the parent of
    # .rubocop_cache) is removed afterwards anyway.
    RuboCop::ResultCache.inhibit_cleanup = true
  end

  # Wrap all cli specs in `aggregate_failures` so that the expected and
  # actual results of every expectation per example are shown. This is
  # helpful because it shows information like expected and actual
  # $stdout messages while not using `aggregate_failures` will only
  # show information about expected and actual exit code
  around do |example|
    aggregate_failures(&example)
  end

  after do
    RuboCop::ResultCache.inhibit_cleanup = false
  end
end
