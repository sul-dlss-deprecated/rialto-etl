# frozen_string_literal: true

RSpec::Matchers.define :have_same_triples do |graph1|
  match do |graph2|
    # Compares statements only, ignoring graph names
    return false unless graph1.size == graph2.size

    graph1.each_triple { |s, o, p| return false unless graph2.has_triple?([s, o, p]) }
    true
  end

  failure_message do |_|
    'graphs do not contain same triples'
  end

  failure_message_when_negated do |_|
    'graphs contain the same triples'
  end

  description do
    'compares triples, ignoring graph names'
  end
end

RSpec::Matchers.define :has_quad do |quad|
  match do |repository|
    repository.has_quad?(quad)
  end

  failure_message do |_|
    'repository does not have quad'
  end

  failure_message_when_negated do |_|
    'repository has quad'
  end

  description do
    'check repository for quad ([subject, predicate, object, graph])'
  end
end

RSpec::Matchers.alias_matcher :have_quad, :has_quad

RSpec::Matchers.define :has_quads do |quads|
  match do |repository|
    quads.all? { |quad| repository.has_quad?(quad) }
  end

  failure_message do |_|
    'repository does not have quads'
  end

  failure_message_when_negated do |_|
    'repository has quads'
  end

  description do
    'check repository for quads ([subject, predicate, object, graph])'
  end
end

RSpec::Matchers.alias_matcher :have_quads, :has_quads
