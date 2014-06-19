fs      = require 'fs'
{inspect} = require 'util'
walkdir = require 'walkdir'
Parser  = require '../src/parser'
Referencer = require '../src/util/referencer'
Generator = require '../src/generator'

{diff}    = require 'jsondiffpatch'
_         = require 'underscore'
_.str     = require 'underscore.string'
require('jasmine-focused')

describe "Parser", ->
  parser = null

  constructDelta = (filename, hasReferences = false) ->
    source = fs.readFileSync filename, 'utf8'

    parser.parseContent source, filename

    expected = JSON.stringify(JSON.parse(fs.readFileSync filename.replace(/\.coffee$/, '.json'), 'utf8'), null, 2)
    generated = if hasReferences then followReferences(parser) else JSON.stringify(parser.toJSON(), null, 2)

    diff(expected, generated)
    checkDelta(expected, generated, diff(expected, generated))

  followReferences = (parser) ->
    parser.parseFile "spec/templates/methods/method_example.coffee"
    parser.parseFile "spec/templates/methods/curly_method_documentation.coffee"
    parser.parseFile "spec/templates/methods/fixtures/private_class.coffee"

    # since delegation happens in the generator, we need to force that magic here
    generator = new Generator(parser,
                              noOutput: true
                              stats: true
                              extras: []
                              quiet: false
                            )
    referencer = new Referencer(parser.classes, parser.mixins, {quiet: false})
    for clazz in parser.classes
      methods = clazz.getMethods()

      # resolve all delegations in methods
      for method in methods
        delegation = method.doc.delegation
        if delegation
          originalStatus = method.doc.status
          [method.doc, method.parameters] = referencer.resolveDelegation(method, delegation, clazz)
          method.doc.status = originalStatus

    # [0], because we don't want the parsed files in the resulting JSON
    JSON.stringify([parser.toJSON()[0]], null, 2)

  checkDelta = (expected, generated, delta) ->
    if delta?
      console.error expected, generated
      console.error(delta)
      expect(delta).toBe(undefined)

  beforeEach ->
    parser = new Parser({
      inputs: []
      output: ''
      extras: []
      readme: ''
      title: ''
      quiet: false
      private: true
      verbose: true
      github: ''
    })

  describe "Classes", ->
    it 'understands descriptions', ->
      constructDelta("spec/templates/classes/class_description_markdown.coffee")

    it 'understands documentation', ->
      constructDelta("spec/templates/classes/class_documentation.coffee")

    it 'understands extends', ->
      constructDelta("spec/templates/classes/class_extends.coffee")

    it 'understands empty classes', ->
      constructDelta("spec/templates/classes/empty_class.coffee")

    it 'understands exporting classess', ->
      constructDelta("spec/templates/classes/export_class.coffee")

    it 'understands inner classes', ->
      constructDelta("spec/templates/classes/inner_class.coffee")

    it 'understands namespaced classes', ->
      constructDelta("spec/templates/classes/namespaced_class.coffee")

    it 'understands simple classes', ->
      constructDelta("spec/templates/classes/simple_class.coffee")

  describe "non class files", ->
    it 'understands descriptions', ->
      constructDelta("spec/templates/files/non_class_file.coffee")

  describe "Methods", ->
    it 'understands assigned parameters classes', ->
      constructDelta("spec/templates/methods/assigned_parameters.coffee")

    it 'understands class methods', ->
      constructDelta("spec/templates/methods/class_methods.coffee")

    it 'understands curly notation', ->
      constructDelta("spec/templates/methods/curly_method_documentation.coffee")

    it 'understands hash parameters', ->
      constructDelta("spec/templates/methods/hash_parameters.coffee")

    it 'understands instance methods', ->
      constructDelta("spec/templates/methods/instance_methods.coffee")

    it 'understands links in methods', ->
      constructDelta("spec/templates/methods/links.coffee")

    it 'understands method delegation', ->
      constructDelta("spec/templates/methods/method_delegation.coffee", true)

    it 'understands method delegation from public to private', ->
      constructDelta("spec/templates/methods/method_delegation_as_private.coffee", true)

    it 'understands basic methods', ->
      constructDelta("spec/templates/methods/method_example.coffee")

    it 'understands methods with paragraph descriptions for parameters', ->
      constructDelta("spec/templates/methods/method_paragraph_param.coffee")

    it 'understands methods with no descriptions', ->
      constructDelta("spec/templates/methods/method_shortdesc.coffee")

    it 'understands optional arguments', ->
      constructDelta("spec/templates/methods/optional_arguments.coffee")

    it 'understands paragraph length descriptions', ->
      constructDelta("spec/templates/methods/paragraph_desc.coffee")

    it 'understands preprocessor flagging for visibility', ->
      constructDelta("spec/templates/methods/preprocessor_flagging.coffee")

    fit 'understands prototypical methods', ->
      constructDelta("spec/templates/methods/prototypical_methods.coffee")

    it 'understands return values', ->
      constructDelta("spec/templates/methods/return_values.coffee")

    it 'understands paragraph length return values', ->
      constructDelta("spec/templates/methods/return_values_long.coffee")
