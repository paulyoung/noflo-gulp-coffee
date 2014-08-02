{Component, InPorts, OutPorts} = require 'noflo'
coffee = require 'gulp-coffee'


class CompileCoffeeScript extends Component

  description: 'Equivalent to gulp-coffee'
  icon: 'coffee'

  constructor: ->
    @options = null

    @inPorts = new InPorts
      options:
        datatype: 'object'
        description: 'The options parameter to be passed to gulp-coffee'

      stream:
        datatype: 'object'
        description: 'The stream to be piped to gulp-coffee'
        required: true

    @outPorts = new OutPorts
      stream:
        datatype: 'object'
        description: 'The stream returned from piping to gulp-coffee'

      error:
        datatype: 'object'
        description: 'An error emitted when compiling with gulp-coffee'


    @inPorts.options.on 'data', (data) =>
      @options = data

    @inPorts.stream.on 'data', (data) =>
      coffeeStream = coffee @options
      coffeeStream.on 'error', (error) => @outPorts.error.send error
      stream = data.pipe coffeeStream
      @outPorts.stream.send stream


module.exports =
  getComponent: -> new CompileCoffeeScript
