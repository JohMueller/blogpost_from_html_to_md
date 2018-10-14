### get all blogposts and save as markdown files


library(rvest)
library(stringr)
library(xml2)

# step 1: get all links to blogposts

index <- read_html("https://correlaid.org/blog/")

index <- index %>%
  html_nodes(".row a") %>% 
  html_attr('href') # extract all links from the index page

urls <- index[grepl("posts", index)] # filter to extract only links to blogposts
names <- str_replace(urls, "https://correlaid.org/blog/posts/", "") # isolate name of blogposts

# step 2: write function to get meta_data for the blogpost


get_meta_information <- function(url){
  
  #Reading the HTML from the website
  webpage <- read_html(html_session(url))
  
  #Gather meta information
  title <- html_text(html_nodes(webpage, 'h2')) # title 
  subtitle <- html_text(html_nodes(webpage, '.subheading')) # subtitle
  description <- html_text(html_nodes(webpage, '#small-header p')[1]) #description long
  
  written_by <- unlist(strsplit(description," "))[3] # author
  
  full_date <- paste(unlist(strsplit(description," "))[5:7], collapse = " ")
  full_date_clean <- as.Date(full_date, format = "%d %B, %Y") # date
  
  # in some blogposts the date is formated in English. For those I have to change the locale
  if(is.na(full_date_clean)){
    Sys.setlocale("LC_TIME", "English") #set locale to English
    full_date_clean <- as.Date(full_date, format = "%d %B, %Y")
    Sys.setlocale("LC_TIME", "German") #set locale back to German
  }
  full_date_clean <- format(full_date_clean, format = "%Y-%m-%dT%H:%M:%S+02:00")
  
  
  header_picture <- webpage %>% html_nodes('#small-header') %>% xml_attr("style")
  header_picture_name <- str_split(header_picture, "posts/")[[1]][2]
  header_picture_name <- gsub("'", "", header_picture_name) # extract only name of the picture
  
  #format the meta information in markdown style
  meta_text <- paste0("---", 
                      "\n title: \"", title,"\"",
                      "\n date: ", full_date_clean,
                      "\n image: \"", header_picture_name,"\"",
                      "\n summary: \"", subtitle,"\"",
                      "\n author: \"", written_by,"\"",
                      "\n---")
  
  return(meta_text)
}

# step 3: write function that transforms .html file to .md file and saves it

html_to_md <- function(url, filename){
  
  # Select Blogpost Text
  webpage <- read_html(html_session(url))
  blogpost_text <- html_nodes(webpage,'.row+ .row .col-lg-offset-2')%>% 
    html_nodes(".post-content") 
  
  # Write cleaned HTML
  write_xml(blogpost_text, 
            file= paste0(filename,".html"))
  
  # Use pandoc to transform saved html to md
  system(paste0("pandoc -s ", filename,".html -o ",filename,".md"))
}
  
# Step 4: Write function to add meta data to .md and clean it up
  
clean_md <- function(filename, meta_info){
  md_file <-file(paste0(filename, ".md"), encoding="UTF-8")
  
  md_text <- readLines(md_file, encoding="UTF-8")
  
  md_text <- gsub("<div>", "", md_text)
  md_text <- gsub("</div>", "", md_text)
  md_text <- gsub("<div class=\"post-content\">", "", md_text)
  md_text <- gsub("https://correlaid.org/media/img/posts/", "", md_text) #clean the path of the images
  
  writeLines(c(meta_info, md_text), md_file)
  
  close(md_file, encoding="latin1") #important: Change the encoding
}


# Run functions for all blogposts

for(i in 1:length(urls)){
  url <- urls[i]
  name <- names[i]
  
  meta <- get_meta_information(url)
  
  html_to_md(url, name)
  clean_md(name, meta)
  
  print(paste0("Processing: ", i, " of ", length(urls), " done"))
}



