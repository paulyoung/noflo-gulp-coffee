{EventEmitter} = require 'events'
{expect} = require 'chai'
noflo = require 'noflo'
SandboxedModule = require 'sandboxed-module'
sinon = require 'sinon'


describe 'CompileCoffeeScript', ->

  fakeCoffeeStream = new EventEmitter
  stub = null


  component = null

  inStream = null
  options = null

  outStream = null
  error = null


  beforeEach ->
    stub = sinon.stub().returns fakeCoffeeStream

    CompileCoffeeScript = SandboxedModule.require '../components/CompileCoffeeScript',
      requires:
        'coffee-script': ->
        'gulp-coffee': stub


    component = CompileCoffeeScript.getComponent()

    inStream = noflo.internalSocket.createSocket()
    component.inPorts.stream.attach inStream

    options = noflo.internalSocket.createSocket()
    component.inPorts.options.attach options

    outStream = noflo.internalSocket.createSocket()
    component.outPorts.stream.attach outStream

    error = noflo.internalSocket.createSocket()
    component.outPorts.error.attach error


  describe 'stream (in)', ->

    it 'should be required', ->
      required = component.inPorts.stream.isRequired()
      expect(required).to.be.true

    it 'should be an object', ->
      dataType = component.inPorts.stream.getDataType()
      expect(dataType).to.equal 'object'


    context 'when sent', ->

      it 'should have the stream from gulp-coffee piped to it', ->
        fakeStream = { pipe: (stream) -> stream }
        spy = sinon.spy fakeStream, 'pipe'

        inStream.send fakeStream

        expect(spy.calledOnce).to.be.true
        expect(spy.firstCall.args[0]).to.equal fakeCoffeeStream


      it 'should send the stream from pipe', (done) ->
        fakePipeStream = 'fakePipeStream'
        fakeStream = { pipe: (stream) -> fakePipeStream }

        outStream.on 'data', (data) ->
          try
            expect(data).to.equal fakePipeStream
            done()
          catch e
            done e

        inStream.send fakeStream


  describe 'options', ->

    it 'should not be required', ->
      required = component.inPorts.options.isRequired()
      expect(required).to.be.false

    it 'should be an object', ->
      dataType = component.inPorts.options.getDataType()
      expect(dataType).to.equal 'object'


    context 'when not sent', ->

      it 'should pass null to gulp-coffee', ->
        fakeStream = { pipe: (stream) -> stream }
        inStream.send fakeStream

        expect(stub.calledOnce).to.be.true
        expect(stub.firstCall.args[0]).to.be.null


    context 'when sent', ->

      it 'should be passed to gulp-coffee', ->
        optionsPacket = { bare: true }
        fakeStream = { pipe: (stream) -> stream }

        options.send optionsPacket
        inStream.send fakeStream

        expect(stub.calledOnce).to.be.true
        expect(stub.firstCall.args[0]).to.deep.equal optionsPacket


  describe 'stream (out)', ->

    it 'should not be required', ->
      required = component.outPorts.stream.isRequired()
      expect(required).to.be.false

    it 'should be an object', ->
      dataType = component.outPorts.stream.getDataType()
      expect(dataType).to.equal 'object'


  describe 'error', ->

    it 'should not be required', ->
      required = component.outPorts.error.isRequired()
      expect(required).to.be.false

    it 'should be an object', ->
      dataType = component.outPorts.error.getDataType()
      expect(dataType).to.equal 'object'


    context 'when an error event is emitted', ->

      it 'should be sent', (done) ->
        fakeCoffeeError = new Error
        fakeStream = { pipe: (stream) -> stream }

        error.on 'data', (data) ->
          try
            expect(data).to.equal fakeCoffeeError
            done()
          catch e
            done e

        inStream.send fakeStream
        fakeCoffeeStream.emit 'error', fakeCoffeeError
