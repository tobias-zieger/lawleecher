require 'net/http'
require 'date/format'

################################################################################
# declaration of some important parameters of the program
################################################################################

types = ["CNS", "COD", "SYN", "AVC"]
types = ["SYN"]

#year, empty string for "all years"
year = ''
#year = '1998'

numberOfMaxHitsPerPage = 10000 #max on the web front is 99

separator = '#' #separator for attributes in file

#things to crawl out of web page, array order determines the order in the file
categories = ['Type', 'Fields of activity', 'Legal basis', 'Procedures', 'Type of File', 'Primarily Responsible']

fileName = 'export.csv'

#flag signalling whether there has been at least one error, if flag is set
thereHaveBeenErrors = false

#this list contains all keys for the process steps in correct order
globalProcessStepNamesList = []

################################################################################
# helper function which gets redirection requests up to 10 steps deep
################################################################################
require 'uri'

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



#removes whitespaces and HTML tags from a given string
#maintains single word spacing blanks
def removeDust(string)

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



# def insertStepNameIntoglobalProcessStepNamesList(stepName)
#     globalProcessStepNamesListif stepName
# end




################################################################################
# program
################################################################################
# algorithm:
# first, find all law ids to have a maximum number for the progress bar
# second, crawl each page
# third, write all to file

################################################################################
# STEP 1: find all law ids
################################################################################

#array containing all law ids
lawIDs = Array.new

types.each do |type|

    puts "looking for #{type} laws..."
    # start query for current type
    # todo: key => value, damit mans besser lesen kann
    response = Net::HTTP.start('ec.europa.eu').post('/prelex/liste_resultats.cfm?CL=en', "doc_typ=&docdos=dos&requete_id=0&clef1=#{type}&doc_ann=&doc_num=&doc_ext=&clef4=&clef2=#{year}&clef3=&LNG_TITRE=EN&titre=&titre_boolean=&EVT1=&GROUPE1=&EVT1_DD_1=&EVT1_MM_1=&EVT1_YY_1=&EVT1_DD_2=&EVT1_MM_2=&EVT1_YY_2=&event_boolean=+and+&EVT2=&GROUPE2=&EVT2_DD_1=&EVT2_MM_1=&EVT2_YY_1=&EVT2_DD_2=&EVT2_MM_2=&EVT2_YY_2=&EVT3=&GROUPE3=&EVT3_DD_1=&EVT3_MM_1=&EVT3_YY_1=&EVT3_DD_2=&EVT3_MM_2=&EVT3_YY_2=&TYPE_DOSSIER=&NUM_CELEX_TYPE=&NUM_CELEX_YEAR=&NUM_CELEX_NUM=&BASE_JUR=&DOMAINE1=&domain_boolean=+and+&DOMAINE2=&COLLECT1=&COLLECT1_ROLE=&collect_boolean=+and+&COLLECT2=&COLLECT2_ROLE=&PERSON1=&PERSON1_ROLE=&person_boolean=+and+&PERSON2=&PERSON2_ROLE=&nbr_element=#{numberOfMaxHitsPerPage.to_s}&first_element=1&type_affichage=1")

    content = response.body


#puts content[content.size-2500..content.size-700]

    # check, whether all hits are on the page
    # there are two ways to check it, we use both for safety reasons

    # first, compare the last number with the max number (e.g. 46/2110)
    # if it's equal, all hits are on this page, which is good

    lastEntryOnPage = content[/\d{1,5}\/\d{1,5}(?=<\/div>\s*<\/TD>\s*<\/TR>\s*<TR bgcolor=\"#(ffffcc|ffffff)\">\s*<TD colspan=\"2\" VALIGN=\"top\">\s*<FONT CLASS=\"texte\">.*<\/FONT>\s*<\/TD>\s*<\/TR>\s*<\/table>\s*<center>\s*<TABLE border=0 cellpadding=0 cellspacing=0>\s*<tr align=\"center\">\s*<\/tr>\s*<\/table>\s*<\/center>\s*<!-- BOTTOM NAVIGATION BAR)/]

#exit 0
    lastEntry, maxEntries = lastEntryOnPage.split("/", 2)

    #TODO:EXCEOTION werfen
    puts "ALARM" unless lastEntry == maxEntries


    # second, the pagination buttons must not be present (at least no "page 2" button)
    #TODO:EXCEOTION werfen
    puts "ALARM" unless nil === content[/<td align="center"><font size="-2" face="arial, helvetica">2<\/font><br\/>/]


    puts "#{maxEntries} laws found for #{type}"


    #fetch out ids for each single law as array and append it to the current set of ids
    #the uniq! removes double ids (<a href="id">id</a>)
    lawIDs += (content.scan /\d{1,6}(?=" title="Click here to reach the detail page of this file">)/).uniq!

end

#now, all law IDs are contained in the array

#assure that there are no doublicated ids in the array (which should not be the case)
numberOfLaws = lawIDs.size
lawIDs.uniq!

#TODO: excepotion
puts "ALARM, es gab id-dopplungen" if lawIDs.size != numberOfLaws

puts "#{numberOfLaws} laws found in total"


################################################################################
# STEP 2: crawl each page
################################################################################

#array containing all law information
results = Array.new


# for each lawID, submit HTTP GET request for fetching out the information of interest
currentLaw = 1
lawIDs[1..10].each do |lawID|

#lawID = 105604

    begin # start try block

        metaStartTime = Time.now

        puts "retrieving law ##{lawID} (#{currentLaw}/#{numberOfLaws})"
        response = fetch("http://ec.europa.eu/prelex/detail_dossier_real.cfm?CL=en&DosId=#{lawID}")
        content = response.body

        # prepare array containing all information for the current law
        arrayEntry = Hash.new

        # since ruby 1.8.6 cannot handle positive look-behinds, the crawling is two-stepped


        # find out the value for "fields of activity"
        begin
            fieldsOfActivity = content[/Fields of activity:<\/font>\s*<\/center>\s*<\/td>\s*<td BGCOLOR="#EEEEEE">\s*<font face="Arial,Helvetica" size=-2>\s*.*?(?=<\/tr>)/m]
            fieldsOfActivity.gsub!(/Fields of activity:<\/font>\s*<\/center>\s*<\/td>\s*<td BGCOLOR="#EEEEEE">\s*<font face="Arial,Helvetica" size=-2>/, '')
            fieldsOfActivity = removeDust(fieldsOfActivity)
        rescue
            #this law does not have "fields of activity" data
            fieldsOfActivity = '[fehlt]'
        end
        arrayEntry['Fields of activity'] = fieldsOfActivity




        # find out the value for "legal basis"
        begin
            legalBasis = content[/Legal basis:\s*<\/font>\s*<\/center>\s*<\/td>\s*<td BGCOLOR="#FFFFFF">\s*<font face="Arial,Helvetica" size=-2>.*?(?=<\/tr>)/m]
            legalBasis.gsub!(/Legal basis:\s*<\/font>\s*<\/center>\s*<\/td>\s*<td BGCOLOR="#FFFFFF">\s*<font face="Arial,Helvetica" size=-2>/, '')
            legalBasis = removeDust(legalBasis)
        rescue
            #this law does not have "legal basis" data
            legalBasis = '[fehlt]'
        end
        arrayEntry['Legal basis'] = legalBasis




        # find out the value for "procedures"
        begin
            procedures = content[/Procedures:<\/font>\s*<\/center>\s*<\/td>\s*<td BGCOLOR="#EEEEEE">\s*<font face="Arial,Helvetica" size=-2>.*?(?=<\/tr>)/m]
            procedures.gsub!(/Procedures:<\/font>\s*<\/center>\s*<\/td>\s*<td BGCOLOR="#EEEEEE">\s*<font face="Arial,Helvetica" size=-2>/, '')
            # convert all \t resp. \r\n into blanks
            procedures = removeDust(procedures)
            #if "procedures" contains a value for commission and council, remove the commission value
            procedures.gsub!(/.*Commission ?: ?.*?(?=Council ?: ?)/, '') if procedures[/.*Commission.*Council.*/] != nil
        rescue
            #this law does not have "procedures" data
            procedures = '[fehlt]'
        end
        arrayEntry['Procedures'] = procedures




        # find out the value for "type of file"
        begin
            typeOfFile = content[/Type of file:<\/font>\s*<\/center>\s*<\/td>\s*<td BGCOLOR="#FFFFFF">\s*<font face="Arial,Helvetica" size=-2>.*?(?=<\/tr>)/m]
            typeOfFile.gsub!(/Type of file:<\/font>\s*<\/center>\s*<\/td>\s*<td BGCOLOR="#FFFFFF">\s*<font face="Arial,Helvetica" size=-2>/, '')
            # convert all \t resp. \r\n into blanks
            typeOfFile = removeDust(typeOfFile)
            #if "type of file" contains a value for commission and council, remove the commission value
            typeOfFile.gsub!(/.*Commission ?: ?.*?(?=Council ?: ?)/, '') if typeOfFile[/.*Commission.*Council.*/] != nil
        rescue
            #this law does not have "type of file" data
            typeOfFile = '[fehlt]'
        end
        arrayEntry['Type of File'] = typeOfFile




        # find out the value for "primarily responsible"
        begin
            primarilyResponsible = content[/Primarily responsible<\/font><\/font><\/td>\s*<td VALIGN=TOP><font face="Arial"><font size=-2>.*?(?=<\/tr>)/m]
            primarilyResponsible.gsub!(/Primarily responsible<\/font><\/font><\/td>\s*<td VALIGN=TOP><font face="Arial"><font size=-2>/, '')
            # convert all \t resp. \r\n into blanks
            primarilyResponsible = removeDust(primarilyResponsible)
        rescue
            #this law does not have "primarily responsible" data
            primarilyResponsible = '[fehlt]'
        end
        arrayEntry['Primarily Responsible'] = primarilyResponsible




        # find out the law type (has been forgotten since only law IDs were saved)
        begin
            type = content[/<font face="Arial">\s*<font size=-1>\d{4}\/\d{4}\/(AVC|COD|SYN|CNS)(?=<\/font>\s*<\/font>)/]
            type.gsub!(/<font face="Arial">\s*<font size=-1>\d{4}\/\d{4}\//, '')
        rescue
            #this law does not have "type" data
            type = '[fehlt]'
        end
        arrayEntry['Type'] = type




        # find out the process duration information
        # create a hash with a time object as key and the name of the process step as value
        # then it will be automatically sorted by time and we can give out the values one after another
        begin
            #puts content[40000..50000]
            processSteps = content[/<strong>&nbsp;&nbsp;Events:<\/strong><br><br>\s*<table.*?(?=<\/table>\s*<p><u><font face="arial"><font size=-2>Activities of the institutions:)/m]
            processSteps.gsub!(/<strong>&nbsp;&nbsp;Events:<\/strong><br><br>\s*<table border="0" cellpadding="0" cellspacing="1">\s*<tr>\s*<td>\s*<div align="left">\s*<span class="exemple">\s*<a href="#\d{5,6}" style="color: Black;">\s*/, '')
            processSteps = processSteps.split(/\s*<\/span>\s*<\/div>\s*<\/td>\s*<\/tr>\s*<tr>\s*<td>\s*<div align="left">\s*<span class="exemple">\s*<a href="#\d{5,6}" style="color: Black;">\s*/)
            processSteps.last.gsub!(/<\/span>\s*<\/div>\s*<\/td>\s*<\/tr>\s*/, '')


            #iterate over processSteps, do 3 things:
            # first, add the process step name to the global sorted list of process step
            # second, transform date into a time object to calculate with it
            # third, build up Hash (step name => timestamp)
            stepTimeHash = {}

            # create the variable here to have a scope over the next iterator
            @timeOfFirstStep = nil

            processSteps.each do |step|

                stepName, timeStamp = step.split(/<\/a>\s*<br>&nbsp;&nbsp;/)

                #puts stepName + " => " + timeStamp

                #first (add to global list)
                #insertStepNameIntoglobalProcessStepNamesList(stepName)
                globalProcessStepNamesList << stepName if globalProcessStepNamesList.index(stepName) == nil

                #second (parse date)
                parsedDate = Date._parse timeStamp
                time = Time.utc parsedDate[:year], parsedDate[:mon], parsedDate[:mday]

                valueToInsert = timeStamp

                if @timeOfFirstStep == nil
                    @timeOfFirstStep = time
                else
                    #calculate the difference between first and current timeStamp
                    duration = ((time - @timeOfFirstStep) / 60 / 60 / 24).floor
                    valueToInsert = duration
                end

                #third (build up hash)
                stepTimeHash[stepName] = valueToInsert
            end
            arrayEntry['DurationInformation'] = stepTimeHash

#stepTimeHash.each {|i| puts i}




        rescue
           puts 'Something went wrong during calculation of process step duration'
           puts backtrace
        end



        metaEndTime = Time.now
        arrayEntry['MetaDuration'] = metaEndTime - metaStartTime

        #add the law processed above
        results << arrayEntry

        currentLaw += 1

    rescue
        puts "There has been an error with law ##{lawID}. This law will be ignored."
        #puts $.backtrace; end
        thereHaveBeenErrors = true
        raise
    end #of exception handling

#        arrayEntry.each {|i, j| puts "#{i} => #{j}"; puts}
end


#puts globalProcessStepNamesList

#results[0].each {|i, j| puts "#{i} => #{j}"; puts}


################################################################################
# STEP 3: write all to file
################################################################################

file = File.new(fileName, "w")

#write header in file
file.puts((categories + globalProcessStepNamesList).join(separator))

#write data in file
results.each do |law|
    temp = Array.new
    categories.each do |category|
        temp << law[category]
    end

    globalProcessStepNamesList.each do |processStepName|
         temp << law['DurationInformation'].values_at(processStepName) if law['DurationInformation'].key?(processStepName)
    end

    file.puts temp.join(separator)
end



puts "#{results.size} laws written into #{fileName}"

puts 'There have been errors during processing.' if thereHaveBeenErrors


sum = 0
results.each {|i| sum += i['MetaDuration']}
puts "total duration: #{sum / 60} minutes"
averageDuration = sum / results.size
puts "average duration per law: #{averageDuration} seconds"


exit 0

f = File.new("response.html", "w")
f.puts response.body
f.close