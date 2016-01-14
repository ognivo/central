# Central -- это централизованный
# publish / subscribe компонент который может связывать любые модули
# Он полезен в тех ситуациях, когда нужно состыковать между собой 
# два компонента, которые друг о друге еле-еле знают, и этого достаточно.
# Примером такой связи является форма заказа: 
#   когда на первой точке меняется телефон нужно проверить - 
#   не зареган ли он на кого-то уже. этот функционал нет смысла ввязывать в форму,
#   поэтому он просто подписывается через центральный узел.
define ->

  SimpleTunnels   = {}
  PromisedTunnels = {}
  # { 'event_emitter1':
  #     { 'event1': [ handler1, handler2 ] } }

  class PromisedEventData
    constructor: ({last_args, handlers}) ->
      @last_args = last_args || null
      @handlers  = handlers  || []

  emit = (tunnel_name, event_name, event_args) ->
    console.log "Central.emit \t ", tunnel_name, event_name, event_args
    tunnel = SimpleTunnels[tunnel_name]
    if !tunnel
      console.warn "Central.emit \t no listeners in tunnel", tunnel_name
      return
    #
    handlers = tunnel[event_name]
    if !handlers
      console.warn "Central.emit \t no listeners in tunnel", tunnel_name, "on event", event_name
      return
    #
    for handler in handlers
      handler.apply(null, event_args)
    #
    return

  emit_promised = (tunnel_name, event_name, event_args) ->
    console.log "Central.emit_promised \t ", tunnel_name, event_name, event_args
    tunnel = PromisedTunnels[tunnel_name]
    if !tunnel
      if tunnel = SimpleTunnels[tunnel_name]
        console.info "Central.emit_promised upgrading tunnel"
        PromisedTunnels[tunnel_name] = tunnel
        SimpleTunnels[tunnel_name] = null
      else
        PromisedTunnels[tunnel_name] = tunnel = {}
    #
    if event_data = tunnel[event_name]
      event_data.last_args = event_args
      { handlers } = event_data
      #
      for handler in handlers
        handler.apply(null, event_args)
    else
      tunnel[event_name] = new PromisedEventData({last_args: event_args})
    return

   
  listen = (tunnel_name, event_name, handler) ->
    tunnel = null
    if PromisedTunnels[tunnel_name]
      tunnel = PromisedTunnels[tunnel_name]
      if event_data = tunnel[event_name]
        {handlers, last_args} = event_data
        handlers.push(handler)
        if last_args
          handler.apply(null, last_args)
      else
        tunnel[event_name] = new PromisedEventData({handlers: [handler]})
    else
      tunnel = SimpleTunnels[tunnel_name] = SimpleTunnels[tunnel_name] || {}
      handlers = tunnel[event_name] = tunnel[event_name] || []
      handlers.push(handler)
    return


  { emit
  , emit_promised
  , listen }
