# Copyright (c) 2008, Tobias Vogel (tobias@vogel.name) (the "author" in the following)
# All rights reserved.
#
# Redistribution and use in source and binary forms, with or without
# modification, are permitted provided that the following conditions are met:
#     * Redistributions of source code must retain the above copyright
#       notice, this list of conditions and the following disclaimer.
#     * Redistributions in binary form must reproduce the above copyright
#       notice, this list of conditions and the following disclaimer in the
#       documentation and/or other materials provided with the distribution.
#     * The name of the author must not be used to endorse or promote products
#       derived from this software without specific prior written permission.
#
# THIS SOFTWARE IS PROVIDED BY THE AUTHOR ``AS IS'' AND ANY
# EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED
# WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE
# DISCLAIMED. IN NO EVENT SHALL THE AUTHOR BE LIABLE FOR ANY
# DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES
# (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES;
# LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND
# ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT
# (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS
# SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.

class Configuration # and settings

  # year filter to apply (empty string for all years)
  def Configuration.year
    ''
    '1970'      # to temporarily reduce the number of laws to crawl
  end
  
  # maximum hits per form submit (originally: 99, default: 20)
  def Configuration.numberOfMaxHitsPerPage
    1000000
  end
  
  # csv file column separator
  def Configuration.separator
    ';'#'#'
  end

  # the text which is put if a key has no value on the website
  def Configuration.missingEntry
    '[fehlt]'
  end
  
  # categories to crawl
  def Configuration.categories
    ['Type', 'ID', 'Upper left identifier', 'Upper center identifier', 'Short description', 'Fields of activity', 'Legal basis', 'Procedures', 'Type of File', 'Primarily Responsible', 'DurationInformation']
  end
  
  # file name of the export
  @@filename = "#{Dir.pwd}/export.csv"
  def Configuration.filename
    @@filename
  end
  def Configuration.filename= filename
    @@filename = filename
  end
  
  # version of the program
  def Configuration.version
    '1.2'
  end

  # number of parser threads to use
  @@numberOfParserThreads = 10
  def Configuration.numberOfParserThreads
    @@numberOfParserThreads
  end
  def Configuration.numberOfParserThreads= numberOfParserThreads
    @@numberOfParserThreads = numberOfParserThreads
  end

  # flag to overwrite the output file if it is existing already
  @@overwritePermission = false
  def Configuration.overwritePermission
    @@overwritePermission
  end
  def Configuration.overwritePermission= overwritePermission
    @@overwritePermission = overwritePermission
  end

  # flag whether or not to use the GUI
  @@guiEnabled = true
  def Configuration.guiEnabled
    @@guiEnabled
  end
  def Configuration.guiEnabled= guiEnabled
    @@guiEnabled = guiEnabled
  end
end