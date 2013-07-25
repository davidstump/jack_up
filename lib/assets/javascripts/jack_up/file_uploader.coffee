railsFormData = ->
  csrfParam = $('meta[name=csrf-param]').attr('content')
  csrfToken = $('meta[name=csrf-token]').attr('content')

  formData = new FormData()
  formData.append(csrfParam, csrfToken)

  formData

class @JackUp.FileUploader
  constructor: (@options) ->
    @path = @options.path
    @fileParam = @options.fileParam || 'file'
    @responded = false

  _onProgressHandler: (file) =>
    (progress) =>
      if progress.lengthComputable
        percent = progress.loaded/progress.total*100
        @trigger 'upload:percentComplete', percentComplete: percent, progress: progress, file: file

        if percent == 100
          @trigger 'upload:sentToServer', file: file

  _onReadyStateChangeHandler: (file) =>
    (event) =>
      status = null
      return if event.target.readyState != 4

      try
        status = event.target.status
      catch error
        return

      acceptableStatuses = [200, 201]
      acceptableStatus = acceptableStatuses.indexOf(status) > -1

      if status > 0 && !acceptableStatus
        @trigger 'upload:failure', responseText: event.target.responseText, event: event, file: file

      if acceptableStatus && event.target.responseText && !@responded
        @responded = true
        @trigger 'upload:success', responseText: event.target.responseText, event: event, file: file

  upload: (file) ->
    console.log "uploading"
    xhr = new XMLHttpRequest()
    xhr.upload.addEventListener 'progress', @_onProgressHandler(file), false
    xhr.addEventListener 'readystatechange', @_onReadyStateChangeHandler(file), false

    xhr.open 'POST', @path, true

    formData = railsFormData()
    console.log "with csrf: " + formData
    formData.append(@fileParam, file)

    @trigger 'upload:start', file: file
    console.log "sending: " + formData
    xhr.send formData

_.extend JackUp.FileUploader.prototype, JackUp.Events