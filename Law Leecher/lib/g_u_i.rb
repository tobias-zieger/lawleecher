require 'gtk2'

class GUI
  def initialize(theCore)
    @theCore = theCore
    
    window = Gtk::Window.new('Law Leecher')
    window.set_border_width 10
    #window.set_size_request 500, 200
    window.set_default_size 1, 1
    window.set_resizable false


    table = Gtk::Table.new(5, 6, false)
    table.set_column_spacings 30
    table.set_row_spacings 5
    #table.set_size_request 300, 300



    welcomeLabel = Gtk::Label.new("Bedienung:\n1.) Dateinamen festlegen\n2.) Start drücken\n\n")
    welcomeLabel.justify= Gtk::JUSTIFY_LEFT

    fileChooserTextLabel = Gtk::Label.new('Dateiname')
    fileNameEntry = Gtk::Entry.new()
    fileNameEntry.set_text @theCore.filename
    fileChooserButton = Gtk::Button.new('Durchsuchen...')

    
    overWriteButton = Gtk::ToggleButton.new()
    overWriteButtonLabel = Gtk::Label.new('Vorhandene Datei überschreiben')
    

    startButton = Gtk::Button.new('Start')



    #progressTextLabel = Gtk::Label.new('Fortschritt')

    @progressBar = Gtk::ProgressBar.new
    @progressBar.text = ''



    #statusTextLabel = Gtk::Label.new('Status')

    @statusLabel = Gtk::Label.new
    @statusLabel.justify= Gtk::JUSTIFY_LEFT






    #signals #######################################################################

    window.signal_connect('delete_event') {Gtk::main_quit}


    fileChooserButton.signal_connect('clicked') {
        fileChooser = Gtk::FileSelection.new('Export speichern unter...')
        fileChooser.show_all
        fileChooser.ok_button.signal_connect('clicked') do
            @theCore.filename= fileNameEntry.text = fileChooser.filename
            
            fileChooser.destroy
        end

        fileChooser.cancel_button.signal_connect('clicked') do
            fileChooser.destroy
        end
    }

    fileNameEntry.signal_connect('key_release_event') {
      puts @theCore.filename= fileNameEntry.text
    }
    
    
    startButton.signal_connect('clicked') {
      if @theCore.readyToStart?(overWriteButton.active?)
        startButton.set_sensitive false
        while Gtk.events_pending?
          Gtk.main_iteration
        end
        @theCore.startProcess
  #      10000.times {
  #        @progressBar.set_fraction(progressBar.fraction + 0.0001)
  #        100000.times {1}
  #        while Gtk.events_pending?
  #          Gtk.main_iteration
  #        end
  #      }
  #      #5.times {@progressBar.set_fraction [1, progressBar.fraction + 0.1].min}
  #      #rechnelange *@progressBar
        startButton.set_sensitive true
      else
        dialog = Gtk::MessageDialog.new(window,
                                        Gtk::Dialog::DESTROY_WITH_PARENT,
                                        Gtk::MessageDialog::ERROR,
                                        Gtk::MessageDialog::BUTTONS_CLOSE,
                                        "Die Datei #{fileNameEntry.text} existiert bereits und das Häkchen zum Überschreiben ist nicht gesetzt.")
        dialog.run
        dialog.destroy
      end
    }







    #pack ##########################################################################

    window.add(table)

    table.attach(welcomeLabel, 0, 2, 0, 1, 0, 0, 0, 0)

    table.attach(fileChooserTextLabel, 0, 1, 1, 2, 0, 0, 0, 0)
    table.attach(fileNameEntry, 1, 5, 1, 2, 0, 0, 0, 0)
    table.attach(fileChooserButton, 5, 6, 1, 2, 0, 0, 0, 0)

    table.attach(overWriteButton, 2, 3, 2, 3, 0, 0, 0, 0)
    table.attach(overWriteButtonLabel, 3, 6, 2, 3, 0, 0, 0, 0)
    
    table.attach(startButton, 0, 1, 3, 4, Gtk::FILL, 0, 0, 0)
    #table.attach(progressTextLabel, 0, 2, 3, 4, 0, 0, 0, 0)
    table.attach(@progressBar, 1, 6, 3, 4, Gtk::FILL, 0, 0, 0)

    #table.attach(statusTextLabel, 0, 2, 4, 5, 0, 0, 0, 0)
    table.attach(@statusLabel, 0, 6, 4, 5, 0, 0, 0, 0)

    window.show_all
  end
  
  def warn(message)
    puts message
    puts "ACHTUNG, METHODE NOCH NICHT IMPLEMENTIERT (GUI.warn)"
  end
  
  def run
    Gtk.main
  end
  
  def updateWidgets(info)
    @progressBar.text = info['progressBarText'] if info.has_key? 'progressBarText'
    @progressBar.set_fraction(@progressBar.fraction + info['progressBarIncrement']) if info.has_key? 'progressBarIncrement'
    @statusLabel.text = info['status'] if info.has_key? 'status'

    while Gtk.events_pending?
      Gtk.main_iteration
    end
  end
end