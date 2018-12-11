import {Component} from 'react'
import h from 'react-hyperscript'

import {HashRouter as Router, Route, Redirect, Switch} from 'react-router-dom'

import {APIContext} from './api'
import {UIMain} from './ui-main'
import {Role} from './enum'
import {LoginForm} from './login-form'

class App extends Component
  @contextType: APIContext
  constructor: (props)->
    super props
    @state = {
      people: null
      person: null
      role: null
    }

  allRequiredOptionsAreSet: =>
    console.log @state
    return false unless @state.person?
    return false unless @state.role?
    return true

  renderUI: ({match})=>
    {params: {role}} = match
    {person, people, role: stateRole} = @state
    isValid = (stateRole == role)
    if not isValid
      # We need to allow the user to change roles
      return h Redirect, {to: '/'}

    id = person.person_id
    extraSaveData = null
    nextImageEndpoint = "/image/next"
    allowSaveWithoutChanges = false
    editingEnabled = true
    if role == Role.TAG
      extraSaveData = {tagger: id}
      subtitleText = "Tag"
    else if role == Role.VALIDATE
      extraSaveData = {validator: id}
      nextImageEndpoint = "/image/validate"
      # Tags can be validated even when unchanged
      allowSaveWithoutChanges = true
      subtitleText = "Validate"
    else if role == Role.VIEW
      editingEnabled = false
      nextImageEndpoint = "/image/validate"
      subtitleText = "View"

    console.log "Setting up UI with role #{role}"

    return h UIMain, {
      extraSaveData
      nextImageEndpoint
      allowSaveWithoutChanges
      editingEnabled
      subtitleText
      @props...
    }

  renderLoginForm: =>
    {person, people, role} = @state
    return null unless people?
    if @allRequiredOptionsAreSet()
      return h Redirect, {to: "/action/#{role}"}
    h LoginForm, {
      person, people,
      setPerson: @setPerson
      setRole: @setRole
    }

  renderViewerForImage: ({match})=>
    console.log "Render viewer for image"
    {params: {imageId}} = match
    console.log "Match"
    return h UIMain, {
      editingEnabled: false
      navigationEnabled: false
      subtitleText: h ["View ", h('code',imageId)]
      nextImageEndpoint: "/image/#{imageId}"
      imageId: imageId
      @props...
    }

  render: ->
    h Router, [
      h 'div.app-main', [
        h Switch, [
          h Route, {path: '/', exact: true, render: @renderLoginForm}
          h Route, {path: '/view/:imageId', render: @renderViewerForImage}
          h Route, {path: '/action/:role', render: @renderUI}
        ]
      ]
    ]

  setupPeople: (d)=>
    @setState {people: d}

  setPerson: (item)=>
    {tagger, validator} = item
    tagger = tagger == 1
    validator = validator == 1
    role = null
    if tagger == 1 and validator != 1
      role = Role.TAG
    @setState {person: item, role}

  setRole: (role)=>
    @setState {role}

  componentDidMount: ->
    @context.get("/people/all")
      .then @setupPeople

export {App}
