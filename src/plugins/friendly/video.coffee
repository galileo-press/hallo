(($) ->
	class EmbedCode
		@UNSUPPORTED: 'unsupported'
		@YOUTUBE: 'youtube'
		@VIMEO: 'vimeo'

		@PROVIDERS = [ EmbedCode.YOUTUBE, EmbedCode.VIMEO ]

		constructor: (@id, @provider) ->
			if not @provider in EmbedCode.PROVIDERS
				throw new Error

		generateUrl: (id, provider) ->
			url = null
			switch @provider
				when EmbedCode.YOUTUBE
					url = "//www.youtube.com/embed/#{ id }"
				when EmbedCode.VIMEO
					url = "//player.vimeo.com/video/#{ id }"
			url

		generateThumbnailUrl: (id, provider) ->
			url = null
			switch @provider
				when EmbedCode.YOUTUBE
					url = "//img.youtube.com/vi/#{ id }/0.jpg"
			url

		getThumbnailCode: ->
			html = null
			url = @generateThumbnailUrl @id, @provider
			switch @provider
				when EmbedCode.YOUTUBE
					html = "<img src=\"#{ url }\" data-video=\"#{ @provider }--#{ @id }\" />"
			html

		getEmbedCode: ->
			embedCode = null
			url = @generateUrl @id, @provider
			switch @provider
				when EmbedCode.YOUTUBE
					embedCode = "<iframe data-video=\"#{ @provider }--#{ @id }\" src=\"#{ url }\" width=\"560\" height=\"315\" frameborder=\"0\" webkitAllowFullScreen mozallowfullscreen allowFullScreen></iframe>"
				when EmbedCode.VIMEO
					embedCode = "<iframe data-video=\"#{ @provider }--#{ @id }\" src=\"#{ url }\" width=\"560\" height=\"315\" frameborder=\"0\" webkitAllowFullScreen mozallowfullscreen allowFullScreen></iframe>"
			embedCode

		@getId = (urlOrId) ->
			id = -1
			provider = null
			if urlOrId.indexOf('://') != -1
				# Strip protocol from URL if any
				urlOrId = urlOrId.slice(urlOrId.indexOf('//')) if urlOrId.indexOf('//') != -1

				if urlOrId.indexOf('youtube.com') != -1
					# It's a YouTube URL
					# http://www.youtube.com/watch?v=pqAsIm9_Eg4
					provider = EmbedCode.YOUTUBE
					[url, id] = /^\/\/www.youtube.com\/watch\?v=([\w\d\_]+)$/i.exec urlOrId
				else if urlOrId.indexOf('vimeo.com') != -1
					# todo: Integrate Vimeo
					# http://vimeo.com/73325589
					provider = EmbedCode.VIMEO
					[url, id] = /^\/\/vimeo.com\/([\w\d\_]+)$/i.exec urlOrId
				else
					# Unsupported video provider
					provider = EmbedCode.UNSUPPORTED
			else
				# It's no URL. Will be an YouTube ID, won't it? :D
				provider = EmbedCode.YOUTUBE
				id = urlOrId
			[id, provider]

		@from: (urlOrId) ->
			[id, provider] = EmbedCode.getId(urlOrId)
			new EmbedCode id, provider

	jQuery.widget 'BF.friendly-video-plugin',
		options:
			editable: null
			uuid: ''
			defaultUrl: 'pqAsIm9_Eg4'
			usePlaceholder: false
			dialogOpts:
				title: "YouTube Video"
				buttonTitle: "Insert"
				buttonUpdateTitle: "Update"
				autoOpen: false
				width: 340
				height: 'auto'
				modal: false
				resizable: true
				draggable: true
				dialogClass: 'insert-image-dialog'

		dialog: null
		toolbar: null
		button: null
		currentEditable: null

		_create: ->
			this.element.on 'halloenabled', =>
				return

		populateToolbar: (toolbar) ->
			widget = this

			createDialog = =>
				# Create the form
				buttonTitle = @options.dialogOpts.buttonTitle
				buttonUpdateTitle = @options.dialogOpts.buttonUpdateTitle
				dialog_html = "
						<form action=\"#\" method=\"post\" class=\"videoForm\">
							<input class=\"url\" type=\"text\" name=\"url\"
							       value=\"#{@options.defaultUrl}\" />
							<input type=\"submit\" id=\"addVideoButton\" 
							       value=\"#{ buttonTitle }\"/>
						</form>"

				# Set Id
				$dialog = $("<div>").
					attr('id', "#{@options.uuid}-video-dialog").
					html(dialog_html)

				# Return dialog
				$dialog

			buttonset = jQuery "<span class=\"#{widget.widgetName}\"></span>"
			buttonize = (type) =>
				id = "#{@options.uuid}-#{type}"

				$button = $ '<span></span>'
				$button.hallobutton
					label: "Video"
					icon: "icon-film"
					uuid: @options.uuid
					editable: @options.editable
					command: null
					queryState: false
					cssClass: @options.buttonCssClass

				$button.click ->
					console.log "Click"
					if widget.dialog.dialog "isOpen"
						widget._closeDialog()
					else
						# we need to save the current selection because we will lose focus
						widget.lastSelection = widget.options.editable.getSelection()
						widget._openDialog()
					false

				# Return the finished button
				$button

			@options.editable.element.on "hallodeactivated", (event, data) =>
				if @options.usePlaceholder
					# Replace video placeholders with final video
					placeholders = $('img[data-video]', event.target)
					placeholders.each ->
						$placeholder = $(@)
						data = $placeholder.data('video').split('--')
						[provider, id] = data
						embedCode = new EmbedCode id, provider
						$placeholder.replaceWith embedCode.getEmbedCode()
						return

				widget.currentEditable = $(event.target)
				return

			@options.editable.element.on "halloactivated", (event, data) =>
				if @options.usePlaceholder
					# Replace video videos with placeholders
					placeholders = $('iframe[data-video]', event.target)

					placeholders.each ->
						$iframe = $(@)
						data = $iframe.data('video').split('--')
						[provider, id] = data
						embedCode = new EmbedCode id, provider
						$iframe.replaceWith embedCode.getThumbnailCode()
						return
				return

			# Setup dialog
			@dialog = do createDialog
			@dialog.dialog(@options.dialogOpts)

			# Attach submit handler
			@dialog.find("input[type=submit]").click (e) =>
				do e.preventDefault
				@_insertVideo $('input[name="url"]', e.target.parentNode).val()
				false

			# Attach dialog close handler
			@dialog.on 'dialogclose', =>
				$document = $(document)
				editable = @options.editable
				pos = $document.scrollTop()
				editable.element.focus()
				$document.scrollTop(pos)  # restore scrollbar pos
				editable.keepActivated false
				return

			# Append the button to the toolbar
			@button = buttonize "Video"
			buttonset.append @button
			toolbar.append buttonset

			@toolbar = toolbar
			return

		_openDialog: (iframe) ->
			$iframe = $(iframe)

			widget = this

			$editableEl = $ @options.editable.element
#			xposition = $editableEl.offset().left + $editableEl.outerWidth() + 10
#			yposition = @toolbar.offset().top - $(document).scrollTop() + 10

			# Set position of the dialog
#			@dialog.dialog("option", "position", [xposition, yposition])

			@options.editable.keepActivated true

			# Open dialog
			@dialog.dialog("open")
			return

		_closeDialog: ->
			@dialog.dialog("close")
			return

		_insertVideo: (url) ->
			embedCode = EmbedCode.from url
			html = if @options.usePlaceholder then embedCode.getThumbnailCode() else embedCode.getEmbedCode()

			editable = @options.editable
			editable.restoreSelection @lastSelection

			# Execute contentEditable command
			# see https://developer.mozilla.org/de/docs/Rich-Text_Editing_in_Mozilla
			document.execCommand "insertHTML", null, html

			editable.element.trigger 'change'
			do editable.removeAllSelections
			do @_closeDialog
			return

) jQuery
