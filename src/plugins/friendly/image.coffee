(($) ->
    $.widget "BF.friendly-image-plugin",
        options:
            uuid: ""
            editable: null

            search: null
            searchUrl: null

            upload: null
            uploadUrl: null
            context: null
            token: null

            dialogOpts:
                autoOpen: false
                width: 500
                height: 400
                title: "Insert Images"
                modal: false
                resizable: false
                draggable: true
                dialogClass: 'friendly-image-dialog'
                maxWidth: 250
                maxHeight: 250

        toolbar: null

        populateToolbar: (@toolbar) ->
            widget = this

            # Create a new dialog
            createDialog = =>
                # Create the form
                buttonTitle = "Upload image"
                dialog_html = "
                    <form action=\"#\" method=\"post\" class=\"image-upload-form\">
                        <input type=\"file\" style=\"display:none\" multiple=\"\" accept=\"image/*\" />
                        <button class=\"browse\">Browse</button>
                        <button class=\"upload\" style=\"display:none\">Upload</button>
                        <button class=\"reset\" style=\"display:none\">Reset</button>
                    </form>
                    <div>
                        <ul class=\"image-upload-queue\"></ul>
                        <ul class=\"available-images group\"></ul>
                    </div>"

                # Set Id
                @$dialog = $dialog = $("<div>").
                    attr('id', "#{ @options.uuid }-friendly-image-dialog").
                    html(dialog_html)

                $fileInput = $dialog.find('input[type="file"]')
                $imageUploadQueue = $dialog.find('ul.image-upload-queue')

                $uploadButton = $dialog.find('button.upload')
                $uploadButton.click (e) ->
                    do e.preventDefault
                    $buttons = $('button.remove', $imageUploadQueue)

                    # Hide all remove buttons
                    do $buttons.hide

                    # Start processing of uploads
                    do processUploads = (i = $buttons.length) ->
                        if --i < 0
                            do widget._refreshImages
                            return

                        $button = $($buttons.get(i))
                        $spinner = $button.siblings('.icon-spinner')

                        file = $button.data('file')
                        do $spinner.show
                        #use gx s3upload with context
                        s3upload = new window.S3Upload(
                            token: widget.options.token
                            files: [file]
                            s3_sign_put_url: widget.options.uploadUrl
                            context: widget.options.context
                            onProgress: (percent, message, publicUrl, file) ->
                                percentComplete = percent
                            onFinishS3Put: (public_url, file) =>
                                do $button.click
                                processUploads(i)
                            onError: (status, file) ->
                        )
                        return
                    return false

                $resetButton = $dialog.find('button.reset')
                $resetButton.click (e) ->
                    do e.preventDefault
                    # Click remove button
                    $('button.remove', $imageUploadQueue).each ->
                        $(@).click()
                        return

                    do $browseButton.show
                    do $uploadButton.hide
                    do $resetButton.hide

                    return false

                # Attach handler to browse-button
                $browseButton = $dialog.find('button.browse')
                $browseButton.click (e) ->
                    do e.preventDefault
                    # Fake click at the file-input
                    do $fileInput.click
                    return false

                # Attach handler to image at the available-images list
                $dialog.on 'click', 'ul.available-images img', (e) ->
                    # Insert image
                    widget._insertImage e.currentTarget.src
                    return

                # Attach handler to changes of the file-input
                $fileInput.bind 'change', (e) ->
                    files = e.target.files

                    # Reset queue
                    $resetButton.click()

                    # Hide the queue
                    $imageUploadQueue.hide()

                    # Put files at the queue
                    for file in files
                        $item = $ "<li>
                                <span class=\"filename\">#{ file.name }</span>
                                <span class=\"filetype\">(#{ file.type || 'n/a' })</span>
                                <button class=\"remove\">Remove</button>
                                <i class=\"icon-spinner icon-spin icon-large\" style=\"display:none\"></i>
                            </li>"

                        $removeButton = $item.find('button')
                        $removeButton.data('file', file)
                        $removeButton.click (e) ->
                            do e.preventDefault

                            # Remove the item
                            do $(e.target).parent().remove

                            # Reset the form if the aren't any more items
                            $resetButton.click() if !$imageUploadQueue.children().length

                            return false

                        # Append the new item to the queue
                        $imageUploadQueue.append($item)

                    # Update display
                    do $imageUploadQueue.show

                    # Toggle buttons visibility
                    do $browseButton.hide
                    do $uploadButton.show
                    do $resetButton.show

                    return

                # Return dialog
                $dialog

            # Create a button for the toolbar
            buttonize = (options) =>
                id = "#{@options.uuid}-image-button"

                $button = $ '<span></span>'
                $button.hallobutton
                    label: options.label || 'Image'
                    icon: "icon-camera"
                    uuid: options.uuid
                    editable: @options.editable
                    command: null
                    queryState: false

                $button.click ->
                    if widget.dialog.dialog "isOpen"
                        widget._closeDialog()
                    else
                        # we need to save the current selection because we will lose focus
                        widget.lastSelection = widget.options.editable.getSelection()
                        widget._openDialog()
                    false

                # Return the finished button
                $button

            # Create dialog
            @dialog = do createDialog
            @dialog.dialog @options.dialogOpts

            @dialog.on 'dialogclose', ->
                do widget.options.editable.element.focus
                widget.options.editable.keepActivated false
                return

            # Create button
            @button = buttonize
                uuid: @options.uuid
                label: "Image"

            buttonset = do @button.hallobuttonset

            # Create buttonset
#            buttonset = jQuery "<span class=\"#{widget.widgetName}\"></span>"
            buttonset.append @button

            # Append buttonset to the toolbar
            toolbar.append buttonset

            # Remeber the toolbar for later reference
            @toolbar = toolbar

            @options.editable.element.on "hallodeactivated", (event) ->
                widget._closeDialog()

            jQuery(@options.editable.element).delegate "img", "click", (event) ->
                widget._openDialog()

            return

        # Set up the widget
        #
        # Returns nothing.
        _create: ->
            return

        # Destructor - clean up any modifications your widget has made to the DOM
        #
        # Returns nothing.
        destroy: ->
            return

        cleanupContentClone: (element) ->
            return

        _insertImage: (url) ->
            editable = @options.editable
            editable.restoreSelection @lastSelection

            # Execute contentEditable command
            # see https://developer.mozilla.org/de/docs/Rich-Text_Editing_in_Mozilla
            document.execCommand "insertImage", null, url

            editable.element.trigger 'change'
            do editable.removeAllSelections
            do @_closeDialog
            return

        _refreshImages: ->
            widget = @
            return if @isRefreshing
            @isRefreshing = true
            # Load images from search URL
            $.getJSON @options.searchUrl, (data, status) ->
                # List images at the dialog
                $list = widget.dialog.find('ul.available-images').hide().empty()
                for itemUrl in data.items
                    $list.append "<li><img src=\"#{ data.host }/#{ itemUrl }\" width=\"100\" height=\"100\"></img></li>"

                # Show images list
                do $list.show
                widget.isRefreshing = false
                return

        _openDialog: ->
            widget = @

            $editableEl = $ @options.editable.element

#            xposition = $editableEl.offset().left + $editableEl.outerWidth() + 10
#            yposition = @toolbar.offset().top - $(document).scrollTop() + 10

            # Set position of the dialog
#            @dialog.dialog("option", "position", [xposition, yposition])

            # Save current caret point
            @lastSelection = @options.editable.getSelection()

            @options.editable.keepActivated true

            # Load images from search URL
            do @_refreshImages

            # Open dialog
            widget.dialog.dialog("open")

            return

        _closeDialog: ->
            @dialog.dialog("close")
            return

 ) jQuery
