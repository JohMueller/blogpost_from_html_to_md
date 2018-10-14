### get all blogposts and save as markdown files


library(rvest)
library(stringr)
library(xml2)

# step 1: get all links to blogposts

index <- read_html("https://correlaid.org/blog/")

index <- index %>%
  html_nodes(".row a") %>% 
  html_attr('href') 

urls <- index[grepl("posts", index)]
names <- str_replace(urls, "https://correlaid.org/blog/posts/", "")

# step 2: write function to get meta_data for the blogpost


get_meta_information <- function(url){
  
  #Reading the HTML code from the website
  webpage <- read_html(html_session(url))
  
  #Gather meta information
  title <- html_text(html_nodes(webpage, 'h2'))
  subtitle <- html_text(html_nodes(webpage, '.subheading'))
  description <- html_text(html_nodes(webpage, '#small-header p')[1])
  
  written_by <- unlist(strsplit(description," "))[3]
  
  full_date <- paste(unlist(strsplit(description," "))[5:7], collapse = " ")
  full_date_clean <- as.Date(full_date, format = "%d %B, %Y")
  
  header_picture <- webpage %>% html_nodes('#small-header') %>% xml_attr("style")
  header_picture_name <- str_split(header_picture, "posts/")[[1]][2]
  header_picture_name <- gsub("'", "", header_picture_name)
  
  meta_text <- paste0("---", 
                      "\n title: \"", title,"\"",
                      "\n date: ", full_date_clean,
                      "\n image: /images/blog/", header_picture_name,
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
  md_file <-file(paste0(filename, ".md"))
  
  md_text <- readLines(md_file)
  
  md_text <- gsub("<div>", "", md_text)
  md_text <- gsub("</div>", "", md_text)
  md_text <- gsub("<div class=\"post-content\">", "", md_text)
  md_text <- gsub("https://correlaid.org/media/img/posts/", "/images/blog/", md_text)
  
  writeLines(c(meta_info, md_text), md_file)
  
  close(md_file)
}


# Workflow

for(i in 1:length(urls)){
  url <- urls[i]
  name <- names[i]
  
  meta <- get_meta_information(url)
  
  html_to_md(url, name)
  clean_md(name, meta)
  
  print(paste0("Processing: ", i, " of ", length(urls), " done"))
}

