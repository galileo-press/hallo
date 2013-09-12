(($) ->
	jQuery.widget 'BF.friendly-table-plugin',
		options:
			editable: null
			uuid: ''
			defaultCols: 4
			defaultRows: 5
			dialogOpts:
				title: "Table"
				buttonTitle: "Insert"
				buttonUpdateTitle: "Update"
				autoOpen: false
				width: 560
				height: 'auto'
				modal: false
				resizable: true
				draggable: true
				dialogClass: 'insert-table-dialog'

		dialog: null
		toolbar: null
		button: null

		populateToolbar: (toolbar) ->
			widget = this

			createDialog = =>
				# Create the form
				buttonTitle = @options.dialogOpts.buttonTitle
				buttonUpdateTitle = @options.dialogOpts.buttonUpdateTitle
				dialog_html = "
						<form action=\"#\" method=\"post\" class=\"tableForm\">
							<label for=\"cols\">Anzahl Spalten</label>
							<input class=\"cols\" type=\"text\" name=\"cols\"
							       value=\"#{@options.defaultCols}\" /><br/>
							<label for=\"row\">Anzahl Zeilen</label>
							<input class=\"rows\" type=\"text\" name=\"rows\"
							       value=\"#{@options.defaultRows}\" /><br/>
							<label for=\"\">Erste Zeile als Kopfzeile</label>
							<input class=\"rows\" type=\"checkbox\" name=\"header\"
							       checked=\"checked\" /><br/>
							<input type=\"submit\" id=\"addTableButton\" 
							       value=\"#{ buttonTitle }\"/>
						</form>"

				# Set Id
				$dialog = $("<div>").
					attr('id', "#{@options.uuid}-dialog").
					html(dialog_html)

				# Return dialog
				$dialog

			buttonset = jQuery "<span class=\"#{widget.widgetName}\"></span>"
			buttonize = (type) =>
				id = "#{@options.uuid}-#{type}"

				$button = $ '<span></span>'
				$button.hallobutton
					label: "Video"
					icon: "icon-table"
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

			# Setup dialog
			@dialog = do createDialog
			@dialog.dialog(@options.dialogOpts)

			# Attach submit handler
			@dialog.find("input[type=submit]").click (e) =>
				do e.preventDefault
				colCount = $('input[name="cols"]', e.target.parentNode).val()
				rowCount = $('input[name="rows"]', e.target.parentNode).val()
				@_insertTable colCount, rowCount, true
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
			@button = buttonize "Table"
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

		_insertTable: (cols, rows, header) ->
			colsHtml = for num in [1..cols]
				'<td></td>'

			rowsHtml = for num in [1..rows]
				"<tr>#{ colsHtml.join('') }</tr>"

			if true == header
				headerHtml = for num in [1..cols]
					'<th></th>'
				headerHtml = "<thead>#{ headerHtml.join('') }</thead>"

			html = "<table>#{ headerHtml }<tbody>#{ rowsHtml.join('') }</tbody></table>"

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
