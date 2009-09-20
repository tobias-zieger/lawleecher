# TODO lizenz einfügen
class ParserThread
  def initialize #lawID, lock, results
    #    print "parser thread gestartet mit law ##{lawID}\n"
    # the ID of the law, which this thread will parse
    #    @lawID = lawID

    # the mutex to write the thread's result savely
    #    @lock = lock

    # the result variable in which the result will be written
    #    @results = results
  end




  def retrieveAndParseALaw lawID
    @lawID = lawID
    print "das law ist = #{@lawID}\n"
    # to save all process steps on the left
    #    processStepNames = []

    begin # start try block

      # save this to calculate the average duration
      #      metaStartTime = Time.now

      #      informUser({'status' => "Analysiere Gesetz ##{@lawID}",
      #        'progressBarText' => "#{currentLawCount}/#{lawIDs.size}",
      #          'progressBarIncrement' => 1.0 / lawIDs.size})

      response = fetch("http://ec.europa.eu/prelex/detail_dossier_real.cfm?CL=en&DosId=#{@lawID}")
      @content = response.body

      #      p @content[-100..-1]
      # prepare array containing all information for the current law
      arrayEntry = {}



      # check, whether some specific errors occured
      if @content[/<H1>Database Error<\/H1>/]
        puts "Law #{@lawID} produced a data base error and thus, is ommitted."
        return
      end

      if @content[/<H1>Unexpected Error<\/H1>/]
        puts "Law #{@lawID} produced an \"unexpected error\" and thus, is ommitted."
        return
      end

      # check, whether fields of activity follows events immediately: then, it is empty
      if @content[/<strong>&nbsp;&nbsp;Events:<\/strong><br><br>\s*<table border="0" cellpadding="0" cellspacing="1">\s*<\/table>\s*<\/td>\s*<td width="70%" valign="top">\s*<table BORDER=0 CELLSPACING=0 COLS=2 WIDTH="100%" BGCOLOR="#EEEEEE" >\s*<tr>\s*<td BGCOLOR="#AEFFAE">\s*<center>\s*<font face="Arial,Helvetica" size=-2>Fields of activity:<\/font>/]
        puts "Law #{@lawID} is empty."
        return
      end



      # now, find out many different pieces of information

      # the preamble has no key words, so it will be extracted first as whole (for safety) and then is divided into the three parts
      #      @preamble = @content[/<table BORDER=\"0\" WIDTH=\"100%\" bgcolor=\"#C0C0FF\">\s*<tr>\s*<td>\s*<table CELLPADDING=2 WIDTH=\"100%\" Border=\"0\">\s*<tr>\s*<td ALIGN=LEFT VALIGN=TOP WIDTH=\"50%\">\s*<b><font face=\"Arial\"><font size=-1>.*?<\/font><\/font><\/b>\s*<\/td>\s*<td ALIGN=LEFT VALIGN=TOP WIDTH=\"50%\">\s*<b><font face=\"Arial\"><font size=-1>.*?<\/font><\/font><\/b>\s*<\/td>\s*<td ALIGN=RIGHT VALIGN=TOP>\s*<\/td>\s*<\/tr>\s*<tr>\s*<td ALIGN=LEFT VALIGN=TOP COLSPAN=\"3\" WIDTH=\"100%\">\s*<font face="Arial"><font size=-2>.*?<\/font><\/font>\s*<\/td>\s*<\/tr>/m]


      # since ruby 1.8.6 cannot handle positive look-behinds, the crawling is two-stepped

      arrayEntry[Configuration::BLUEBOX_UPPERLEFTIDENTIFIER] = parseSimple(/<table BORDER=\"0\" WIDTH=\"100%\" bgcolor=\"#C0C0FF\">\s*<tr>\s*<td>\s*<table CELLPADDING=2 WIDTH=\"100%\" Border=\"0\">\s*<tr>\s*<td ALIGN=LEFT VALIGN=TOP WIDTH=\"50%\">\s*<b><font face=\"Arial\"><font size=-1>/, /.*?(?=<\/font><\/font><\/b>\s*<\/td>)/, @content)
      arrayEntry[Configuration::BLUEBOX_UPPERCENTERIDENTIFIER] = parseSimple(/<\/font><\/font><\/b>\s*<\/td>\s*<td ALIGN=LEFT VALIGN=TOP WIDTH=\"50%\">\s*<b><font face=\"Arial\"><font size=-1>/, /.*?(?=<\/font><\/font><\/b>\s*<\/td>\s*<td ALIGN=RIGHT VALIGN=TOP>\s*<\/td>\s*<\/tr>\s*<tr>\s*<td ALIGN=LEFT VALIGN=TOP COLSPAN=\"3\" WIDTH=\"100%\">\s*<font face="Arial"><font size=-2>)/, @content)
      arrayEntry[Configuration::BLUEBOX_SHORTDESCRIPTION] = parseSimple(/<\/font><\/font><\/b>\s*<\/td>\s*<td ALIGN=RIGHT VALIGN=TOP>\s*<\/td>\s*<\/tr>\s*<tr>\s*<td ALIGN=LEFT VALIGN=TOP COLSPAN=\"3\" WIDTH=\"100%\">\s*<font face="Arial"><font size=-2>/, /.*?(?=<\/font><\/font>\s*<\/td>\s*<\/tr>)/, @content)

      arrayEntry[Configuration::TYPE] = parseSimple(/<font face="Arial">\s*<font size=-1>(\d{4}\/)?\d{4}\//, /(CNS|COD|SYN|AVC|ACC|PRT|CNB|CNC)(?=<\/font>\s*<\/font>)/, @content)

      arrayEntry[Configuration::GREENBOX_FIELDSOFACTIVITY] = parseSimple(/Fields of activity:<\/font>\s*<\/center>\s*<\/td>\s*<td BGCOLOR="#EEEEEE">\s*<font face="Arial,Helvetica" size=-2>\s*/, /.*?(?=<\/tr>)/, @content)
      arrayEntry[Configuration::GREENBOX_LEGALBASIS] = parseSimple(/Legal basis:\s*<\/font>\s*<\/center>\s*<\/td>\s*<td BGCOLOR="#FFFFFF">\s*<font face="Arial,Helvetica" size=-2>/, /.*?(?=<\/tr>)/, @content)
      arrayEntry[Configuration::GREENBOX_PROCEDURES] = parseSimple(/Procedures:<\/font>\s*<\/center>\s*<\/td>\s*<td BGCOLOR="#EEEEEE">\s*<font face="Arial,Helvetica" size=-2>/, /.*?(?=<\/tr>)/, @content)
      arrayEntry[Configuration::GREENBOX_TYPEOFFILE] = parseSimple(/Type of file:<\/font>\s*<\/center>\s*<\/td>\s*<td BGCOLOR="#FFFFFF">\s*<font face="Arial,Helvetica" size=-2>/, /.*?(?=<\/tr>)/, @content)


      #      if (lastBoxExistsAndIsRelevant?)
      #        arrayEntry['lastBox.TypeOfFile'] = parseLastBoxTypeOfFile
      #      end
      #      p arrayEntry.inspect
      #      p "hallo?"
      #      puts "ergebnis: " + arrayEntry['Last Box Type of File']


      #      # this law seems to be empty, if the following entries are empty (upper left identifier is given, nevertheless)
      #      if arrayEntry['Fields of activity'] == Configuration.missingEntry and
      #          arrayEntry['Legal basis'] == Configuration.missingEntry and
      #          arrayEntry['Procedures'] == Configuration.missingEntry and
      #          arrayEntry['Type of File'] == Configuration.missingEntry and
      #          arrayEntry['Primarily Responsible'] == Configuration.missingEntry and
      #          arrayEntry['Upper center identifier'] == Configuration.missingEntry and
      #          arrayEntry['Short description'] == Configuration.missingEntry
      #        raise Exception.new('empty law')
      #      end


      # timeline items (timestamp, title, and (if available) decision (mode) value)
      allTables = @content[/<table BORDER=0 CELLSPACING=0 COLS=2 WIDTH="100%" BGCOLOR="#EEEEEE" >.*<\/td>\s*<\/tr>\s*<\/table>\s*<!-- BOTTOM NAVIGATION BAR -->/m]
      # separate the tables, each table is an entry in the timeline
      allTables = allTables.split(/(?=<table BORDER=0 CELLSPACING=0 WIDTH="100%" BGCOLOR="#.{6}")/)
      # remove the first one (green table)
      allTables.shift



      arrayEntry[Configuration::TIMELINE] = processTimeline allTables


      # first box items (whatever is in there)
      arrayEntry[Configuration::FIRSTBOX] = processFirstBox allTables.first
      #arrayEntry['firstbox.PrimarilyResponsible'] = parseSimple(/Primarily responsible<\/font><\/font><\/td>\s*<td VALIGN=TOP><font face="Arial"><font size=-2>/, /.*?(?=<\/tr>)/, @content)


      # last box items (if available)
      arrayEntry[Configuration::LASTBOX_DOCUMENTS], arrayEntry[Configuration::LASTBOX_PROCEDURES], arrayEntry[Configuration::LASTBOX_TYPEOFFILE], arrayEntry[Configuration::LASTBOX_NUMEROCELEX] = processLastBox allTables.last



      # OJ Conseil
      # extract "OJ Conseil" from "adoption common position" table
      ojConseil = Configuration.missingEntry
      allTables.each { |table|
        if table[/Adoption common position/]
          ojConseil = parseSimple(/OJ CONSEIL<\/font><\/font><\/td>\s*<td VALIGN=TOP><font face="Arial"><font size=-2>/, /.*?(?=<\/font><\/font><\/td>\s*<\/tr>)/, table)
          break
        end
      }
      arrayEntry[Configuration::OJCONSEIL] = ojConseil
      
      #    end

=begin

      # find out the process duration information
      # create a hash with a time object as key and the name of the process step as value
      # then it will be automatically sorted by time and we can give out the values one after another
      begin
        processSteps = @content[/<strong>&nbsp;&nbsp;Events:<\/strong><br><br>\s*<table.*?(?=<\/table>)/m]
        processSteps.gsub!(/<strong>&nbsp;&nbsp;Events:<\/strong><br><br>\s*<table border="0" cellpadding="0" cellspacing="1">\s*<tr>\s*<td>\s*<div align="left">\s*<span class="exemple">\s*<a href="#\d{5,6}" style="color: Black;">\s*/, '')
        processSteps = processSteps.split(/\s*<\/span>\s*<\/div>\s*<\/td>\s*<\/tr>\s*<tr>\s*<td>\s*<div align="left">\s*<span class="exemple">\s*<a href="#\d{5,6}" style="color: Black;">\s*/)
        processSteps.last.gsub!(/\s*<\/span>\s*<\/div>\s*<\/td>\s*<\/tr>\s*/, '')

        # iterate over processSteps, do 3 things:
        # first, add the process step name to the global list of process steps
        # second, transform date into a time object to calculate with it
        # third, build up Hash (step name => timestamp resp. difference)

        # create the variable here to have a scope over the next iterator
        @timeOfFirstStep = nil


        # defines the offset of the year (since ruby only supports timestamps beginning with
        # 01.01.1970) which is only valid for (and affects only) the current law
        yearOffset = 0

        # container for the largest single duration (= the duration of the whole law)
        # is overwritten in each process step and thus, contains the maximum duration
        # since the dates are ordered chronological on the page
        lastDuration = 0

        # states, whether the process step "Adoption by Commission" has been
        # found in this law already
        # if not, the appropriate hash entry has to be created and set to Configuration.missingEntry
        adoptionByCommissionFoundForThisLaw = false

        #        p processSteps.inspect
        processSteps.each do |step|

          stepName, timeStamp = step.split(/<\/a>\s*<br>&nbsp;&nbsp;/)


          # prevent overwriting process step names of the same name which occured earlier in this law
          # therefore: extend a step name (e.g. "abc") by "A" (=> "abc A"), then "B" (=> "abc B") and so on
          #
          # so: check, whether step name already exists in any level of extension (even without extension)
          # if not: do nothing special and go on
          # if yes: check, which is the highest level
          #   if it's the step name itself, add " A" to it
          #   if there are already extensions, do a .next! to proceed to the next level
          highestLevelOfCurrentStepNameExtension = (arrayEntry.keys.grep(/#{stepName}( \w?)?/)).sort.max
          if highestLevelOfCurrentStepNameExtension != nil
            if highestLevelOfCurrentStepNameExtension == stepName
              stepName += ' A'
            else
              stepName = highestLevelOfCurrentStepNameExtension.next
            end
          end

          processStepNames << stepName


          # save the signature timestamp additionally
          if stepName == 'Signature by EP and Council'
            processStepNames << 'Date of Signature by EP and Council'
            arrayEntry['Date of Signature by EP and Council'] = timeStamp
          end

          # if "Adoption by Commission" has been found, the key hasn't to be
          # set to Configuration.missingEntry in the end
          if stepName == 'Adoption by Commission'
            adoptionByCommissionFoundForThisLaw = true
          end

          #          p timeStamp
          # second (parse date)
          #          parsedDate = Date._parse timeStamp

          # this occurs only with law #115427
          #          parsedDate[:year] = 1986 if parsedDate[:year] == 986


          # this occurs only with law #148799
          #          parsedDate[:year] = 1982 if parsedDate[:year] == 1820


          # if year is critical or (is it not, but) offset has been used in an
          # earlier iteration within this law
          #          if parsedDate[:year] < 1970 or yearOffset != 0
          #            yearOffset = 10 # shift law 10 years into the future
          #          end

          #          time = Time.utc parsedDate[:year] + yearOffset, parsedDate[:mon], parsedDate[:mday]

          #          timeStampOrDuration = timeStamp

          #          if @timeOfFirstStep == nil
          #            @timeOfFirstStep = time
          #          else
          #calculate the difference between first and current timeStamp
          #seconds are returned, not milliseconds (!)
          #            duration = ((time - @timeOfFirstStep) / 60 / 60 / 24).floor
          #            timeStampOrDuration = duration
          #            lastDuration = duration
          #          end

          #third (add duration)
          #arrayEntry[stepName] = timeStampOrDuration
          arrayEntry[stepName] = timeStamp
        end

        #        arrayEntry['DurationInformation'] = lastDuration

        #if there was no "Adoption by Commission" process step,
        #it has to be marked that way
        arrayEntry['Adoption by Commission'] = Configuration.missingEntry unless adoptionByCommissionFoundForThisLaw



      rescue StandardError => ex
        puts 'Something went wrong during calculation of process step duration'
        puts ex.message
        puts ex.backtrace
        thereHaveBeenErrors = true
      end

=end

      #      metaEndTime = Time.now
      #      arrayEntry['MetaDuration'] = metaEndTime - metaStartTime

      arrayEntry[Configuration::ID] = @lawID

      #    arrayEntry.each {|key, value| puts "#{key} -> #{value}"}


      #      p arrayEntry.inspect







      #    @lock.synchronize {
      #add all fetched information (which is stored in arrayEntry) in the results array, finally
      #      @results << arrayEntry

      #        currentLawCount += 1
      #    }

    rescue Exception => ex
      puts "EXCEPTION"
      if ex.class == Errno::ECONNRESET or ex.class == Timeout::Error or ex.class == EOFError
        puts "Zeitüberschreitung bei Gesetz ##{@lawID}. Starte dieses Gesetz nochmal von vorne."
        retry
      elsif ex.message == 'empty law'
        puts "Gesetz #{@lawID} scheint leer zu sein. Dieses Gesetz wird ignoriert."
      else
        puts "Es gab einen echten Fehler mit Gesetz ##{@lawID}. Dieses Gesetz wird ignoriert."
        puts ex.message
        puts ex.class
        puts ex.backtrace
        thereHaveBeenErrors = true
        return @lawID
      end
    end #of exception handling

    return arrayEntry

  end 



  private

  def processTimeline allTables
    # timeline abarbeiten
    timeline = []

    # retrieve data from each table
    allTables.each { |table|
      #table = allTables.first
      # separate the table into table rows (<tr>)
      rows = table.split(/(?=<tr>)/)

      # remove the stuff before the first <tr>
      rows.shift

      # the first <tr>... contains the date and the title of the timeline step
      firstRow = rows.shift
      timestamp = firstRow[/\d\d-\d\d-\d\d\d\d(?=<\/B>\s*<\/font>)/]
      title = parseSimple(/<td ALIGN=CENTER WIDTH=\"\d+%\" BGCOLOR=\"#.{6}\">\s*<font face=\"Arial\">\s*<font size=-2>\s*<B>/, /.*(?=<\/B>\s*<\/font>\s*<\/font>\s*<\/td>\s*<\/tr>\s*)/, firstRow)


      decision = Configuration.missingEntry
      unless rows.empty?
        # the second <tr>... contains "decision" or "decision mode" or none of both
        secondRow = rows.shift
        secondRow.gsub! /<tr>\s*<td width=\"3\">&nbsp;<\/td>\s*<td VALIGN=TOP><font face=\"Arial\"><font size=-2>/, ''
        decision = secondRow[/^Decision (mode)?:/]
        if decision.nil?
          decision = Configuration.missingEntry
        else
          decision = parseSimple(/<font size=-2>/, /.*<\/font><\/font><\/td>\s*<\/tr>/, secondRow)
        end
      end

      timeline << {'titleOfStep' => title, 'timestamp' => timestamp, 'decision' => decision}
    }

    return timeline
  end

  def processLastBox lastTable
    rows = lastTable.split(/(?=<tr>)/)
    # remove the stuff before the first <tr>, immediately
    rows.shift

    # if this table is empty, there is only one <tr> holding the table header
#    if rows.size == 1
#      return Configuration.missingEntry, Configuration.missingEntry, Configuration.missingEntry, Configuration.missingEntry
#    end

    documents = Configuration.missingEntry
    procedures = Configuration.missingEntry
    typeOfFile = Configuration.missingEntry
    numeroCelex = Configuration.missingEntry
    
    #TODO das documents von hinten und dieses in eine funktion auslagern
    rows.each { |row|
      if row[/Documents:/]
        # there can be several documents, thus: split it
        #      documents = rows[1].split /'\)\">\s*<font face=\"Arial\"><font size=-2>/
        documents = row.split /<BR>/
        documents.pop
        #      documents.shift # remove junk here
        documents.collect! {|document|
          parseSimple(/.*<font size=-2>/, /.*(?=<\/font><\/font>\s*(<\/a>)?)/, document)
        }

        documents = documents.join Configuration.innerSeparator


        #      documents.collect! {|document|
        #        parseSimple(/.*<font size=-2>/, /.*(?=<\/font><\/font>\s*(<\/a>)?)/, document)
        #                    clean(document[/.*(?=<\/font>.*)/])
        #                 }



      end

      if row[/Procedures/]
        procedures = parseSimple(/Procedures:<\/font><\/font><\/td>\s*<td VALIGN=TOP><font face=\"Arial\"><font size=-2>/, /.*(?=<\/font><\/font><\/td>\s*<\/tr>)/, rows[2])
      end

      if row[/Type of file/]
        typeOfFile = parseSimple(/Type of file:<\/font><\/font><\/td>\s*<td VALIGN=TOP><font face=\"Arial\"><font size=-2>/, /.*(?=<\/font><\/font><\/td>\s*<\/tr>)/, rows[3])
      end

      if row[/NUMERO CELEX/]
        numeroCelex = parseSimple(/'\)\">\s*<font face=\"Arial\"><font size=-2>/, /.*(?=<\/font><\/font>\s*<\/a>)/, rows[4])
      end
    }
    #  ignoreLastBox = lastTable[/Documents.*Procedures.*Type of file.*NUMERO CELEX/m].nil?
    #  arrayEntry['lastbox.Procedures'] = ignoreLastBox ? Configuration.missingEntry : parseSimple(/Procedures:<\/font><\/font><\td>\s*<td VALIGN=TOP><font face=\"Arial\"><font size=-2>/, /.*<\/font><\/font>/)
    #  arrayEntry['lastbox.TypeOfFile'] = Configuration.missingEntry
    #  arrayEntry['lastbox.NumeroCelex'] = Configuration.missingEntry
    #  arrayEntry['lastbox.Documents'] = ignoreLastBox ? Configuration.missingEntry : parseSimple(//)
    return documents, procedures, typeOfFile, numeroCelex
  end


  # removes whitespaces and HTML tags from a given string
  # maintains single word spacing blanks
  def clean(string)
    #remove HTML tags, if there are any
    string.gsub!(/<.+?>/, '') unless ((string =~ /<.+?>/) == nil)

    #convert &nbsp; into blanks
    string.gsub!(/&nbsp;/, ' ')

    #remove whitespaces
    string.gsub!(/\r/, '')
    string.gsub!(/\n/, '')
    string.gsub!(/\t/, '')

    #remove blanks at end
    string.strip!

    #convert multiple blanks into single blanks
    string.gsub!(/\ +/, ' ')

    return string
  end



  # fetches HTTP requests which use redirects
  def fetch(uri_str, limit = 10)
    # You should choose better exception.
    raise ArgumentError, 'HTTP redirect too deep' if limit == 0

    response = Net::HTTP.get_response(URI.parse(uri_str))
    case response
    when Net::HTTPSuccess then response
    when Net::HTTPRedirection then fetch(response['location'], limit - 1)
    else
      response.error!
    end
  end

  def parseLawType
    # find out the law type
    begin
      type = @content[/<font face="Arial">\s*<font size=-1>(\d{4}\/)?\d{4}\/(AVC|COD|SYN|CNS)(?=<\/font>\s*<\/font>)/]
      type.gsub!(/<font face="Arial">\s*<font size=-1>(\d{4}\/)?\d{4}\//, '')
      raise if type.empty?
    rescue
      # this law does not have "type" data
      type = Configuration.missingEntry
    end
    return type
  end

  #def lastBoxExistsAndIsRelevant?
  #  @content[/<table BORDER=0 CELLSPACING=0 WIDTH="100%" BGCOLOR="#\w{6}">\s*<tr>\s*<td width="1%" BGCOLOR="#\w{6}">&nbsp;<\/td>\s*<td WIDTH="20%" BGCOLOR="#\w{6}">\s*<font face="Arial">\s*<font size=-2>\s*<B>24-10-1995<\/B>\s*<\/font>\s*<\/font>\s*<\/td>\s*<td ALIGN=CENTER WIDTH="69%" BGCOLOR="#\w{6}">\s*<font face="Arial">\s*<font size=-2>\s*<B>Signature by EP and Council<\/B>\s*<\/font>\s*<\/font>/m]
  #end


  #   a general method to extract pieces of a long string (simulating multilength look-behinds)
  #     extracts a substring out of a given string
  #     i.e.: result = string[/(?<=noise1)substring(?=noise2)/m]
  #
  #     where string is given
  #     noise1 is beforepattern
  #     substring and noise2 is behindpattern (should include the (?=...))
  #     returns result (the isolated substring)
  #
  #    to get the result, the following happens
  #    1. beforepattern + behindpattern is extracted from string, behindpattern may contain a lookahead and thus, this noise is not selected
  #    2. beforepattern is deleted
  #    3. since behindpattern consists of .* and some noise, which is not selected from the string, the remaining string is the result
  #
  #    beforepattern is a regexp object
  #    behindpattern is a regexp object
  #    string is a string
  def parseSimple beforePattern, behindPattern, string
    begin
      #      p "neu in parsesimple\n"
      regexp = Regexp.new(beforePattern.source + behindPattern.source, Regexp::MULTILINE)
      result = string[regexp]
      result.gsub! Regexp.new(beforePattern.source, Regexp::MULTILINE), ''
      result = clean(result)
      raise if result.empty?
    rescue
      result = Configuration.missingEntry
    end
    return result
  end

  #def parseLastBoxTypeOfFile
  #  # find out the value for "type of file in the last box"
  #  begin
  #    stringStart = /<tr>\s*<td width="3">&nbsp;<\/td>\s*<td VALIGN=TOP><font face="Arial"><font size=-2>Type of file:<\/font><\/font><\/td>\s*<td VALIGN=TOP><font face="Arial"><font size=-2>/m
  #    p "hier"
  #    x = rml(stringStart, ".*(?=<\/font><\/font><\/td>\s*<\/tr>)")
  #    puts x.nil?
  #    puts x.inspect
  #    puts x.class
  #    p @content[-100..-1]
  #    #      typeOfFileInTheLastBox = @content[rml(stringStart, ".*(?=<\/font><\/font><\/td>\s*<\/tr>)")]
  #    p @content[/<tr>\s*<td width="3">&nbsp;<\/td>\s*<td VALIGN=TOP><font face="Arial"><font size=-2>Type of file:<\/font><\/font><\/td>\s*<td VALIGN=TOP><font face="Arial"><font size=-2>.*(?=<\/font><\/font><\/td>\s*)/]
  #    p @content[/<tr>\s*<td width="3">&nbsp;<\/td>\s*<td VALIGN=TOP><font face="Arial"><font size=-2>Type of file:<\/font><\/font><\/td>\s*<td VALIGN=TOP><font face="Arial"><font size=-2>.*(?=<\/font><\/font><\/td>\s*<\/tr>)/m]
  #    p "piep"
  #    p "inhalt: #{typeOfFileInTheLastBox}"
  #    typeOfFileInTheLastBox = typeOfFileInTheLastBox.gsub! stringStart, ''
  #    # convert all \t resp. \r\n into blanks
  #    typeOfFileInTheLastBox = clean(typeOfFileInTheLastBox)
  #    p "vorm raise"
  #    raise if typeOfFileInTheLastBox.empty?
  #  rescue
  #    # this law does not have "type of file in last box" data
  #    p "im catch"
  #    typeOfFileInTheLastBox = Configuration.missingEntry
  #  end
  #end

  #def rml regexp, string
  #  #    begin
  #  #    r =
  #  Regexp.new(regexp.source + string, Regexp::MULTILINE)
  #  #    puts r.class
  #  #    rescue
  #  #      p "catchblock"
  #  #    end
  #  #return r
  #end

  def processFirstBox table
    tableData = {}
    rows = table.split(/(?=<tr>)/)
    # remove the stuff before the first <tr>, immediately
    rows.shift

    # remove the first row, it is only the title and not of interest, here
    rows.shift


    # extract key and values, thus, iterate over each row, get the row entries
    rows.each { |row|
      # divide it in cells, but remove the junk before the first cell and also remove the first cell which is always empty
      cells = row.split(/<td/)[2..3]
      key = parseSimple(/VALIGN=TOP><font face="Arial"><font size=-2>/, /.*/, cells.first)

      value = Configuration.missingEntry

      # if the key is NUMERO CELEX or Documents, special measures have to be taken
      if key[/Documents:/]
        # there can be several documents, thus: split it
        documents = cells.last.split /<BR>/
        documents.pop # remove junk here

        #        documents = cells.last.split /'\)\">\s*<font face=\"Arial\"><font size=-2>/
        #        documents.shift # remove junk here
        documents.collect! {|document| parseSimple(/.*<font size=-2>/, /.*(?=<\/font><\/font>\s*(<\/a>)?)/, document)
          #          clean(document[/.*(?=<\/font>.*)/])
        }
        documents = documents.join Configuration.innerSeparator
        value = documents
      elsif key[/NUMERO CELEX/]
        value = parseSimple(/'\)\">\s*<font face=\"Arial\"><font size=-2>/, /.*(?=<\/font><\/font>\s*<\/a>)/, cells.last)
      else
        value = parseSimple(/VALIGN=TOP>\s*<font face="Arial"><font size=-2>/, /.*/, cells.last)
      end
      tableData[key] = value
    }

    return tableData


     
  end

end