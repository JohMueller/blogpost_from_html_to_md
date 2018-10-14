# blogpost_from_html_to_md

This is code to scrape all CorrelAid blogposts, translate them from HTML to Markdown and add meta information.

* Step 1: Get all the links to the blogposts
* Step 2: Write a function that a extracts all the meta information (title, author, date, etc.) using html/XML parsing and store it as markdown meta information
* Step 3: Write a function that trasforms the blogpost text from .html to .md. For this I use the Pandoc command line tool which can be called from within R with
  system(paste0("pandoc -s filename.html -o filename.md")) 
* Step 4: Write a function that loads the .md back into R and clean up the image paths and add the meta information generated in step 1.

* Step 5: Run the functions for all 43 blogposts
