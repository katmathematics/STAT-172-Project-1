###
# Authors: Katja Mathesius
# Description: Scrapes the Web for Data
###

from bs4 import BeautifulSoup # For scraping data from web contents
from urllib.request import urlopen # For grabbing data from the web
import ssl # For fixing a connection issue w/ the web scraper
import datetime # For data that can reliably be grabbed up to a current data, this is used to keep the date current
import pandas as pd # For saving data to a csv format
import re # For file
import os # For saving the file to a specific directory
import sys # For taking variables from the command line

# Collects data from the Bonneville Power Administration website
# Ideally we'd like to be able to merge the tables within this step, but for now merge_tables is an unused variable
# Additionally passing a file directory would be good
def get_bpa_data(merge_tables=False,directory="data\\web_data"):

    START_YEAR_BPA = 1999
    BASE_URL_BPA = "https://transmission.bpa.gov/Business/Operations/Outages/OutagesCY"

    # Keeps the loop end at the current year 
    cur_year = datetime.date.today().year

    # Loops through all the available years on the BPA website to accquire all the data
    for year in range(START_YEAR_BPA,cur_year):
        url = BASE_URL_BPA + str(year) + ".htm"
        bpa_soup = order_soup(url)

        tables = {}
        # Pages have multiple tables. this breaks down the webpage into the seperate tables
        for label in bpa_soup.find_all("div", class_ = "tablelabel"):
            values = []
            for sibling in label.find_next_siblings():
                if sibling.name == "tablelabel":  # iterate through siblings until separator is encoutnered
                    break
                values.append(sibling)
            tables[label.text] = values
        
        for key in tables:
            table = tables[key][0]
    
            table_header_html = table.find_all('th')
            tables_headers = []
            for header in table_header_html:
                tables_headers.append(header.get_text())
            
            table_row_html = table.find_all('tr')
            tables_rows = []
            for row_html in table_row_html:
                row = []
                for data in row_html.find_all('td'):
                    row.append(data.get_text())
                tables_rows.append(row)  
            
            filename = str(year) + " " + key + " data"
            filename = CleanFileName(filename)
            filename = AppendDir(filename,directory)

            SaveDataToCSV(tables_rows,tables_headers,filename)  
                   
    return "BPA data was accquired successfully!"

# Appends the desired directory to the filename
def AppendDir(filename,directory="data\\web_data"):
    # Makes the directory to be written to if it doesn't already exist
    if not os.path.exists(os.path.join(os.pardir, directory)):
        os.makedirs(os.path.join(os.pardir, directory))

    partial_loc = directory + "\\" + filename
    full_loc = os.path.join(os.pardir, partial_loc)
    
    return full_loc

# Forces file names to be a snake-cased format
def CleanFileName(filename):
    clean_filename = filename.lower()
    clean_filename = ReplaceIllegalCharacters(clean_filename)
    clean_filename = clean_filename.replace(' ','_') 
    return clean_filename

# Replaces characters that are illegal in file names on windows
def ReplaceIllegalCharacters(text):
    clean_text = text
    # Replace w/ an abbreviation
    ### These '>=' and '<=' replacements HAVE to go first or else the individual replacements will mess them up
    clean_text = clean_text.replace('>=','geq')
    clean_text = clean_text.replace('<=','leq')
    clean_text = clean_text.replace('=','eq')

    # Replace w/ a substition
    clean_text = clean_text.replace('<','[')
    clean_text = clean_text.replace('>',']')

    # Replace w/ a blank space
    clean_text = clean_text.replace('\'',' ')
    clean_text = clean_text.replace('\"',' ')
    clean_text = clean_text.replace('\\',' ')
    clean_text = clean_text.replace('/',' ')
    clean_text = clean_text.replace('*',' ')
    clean_text = clean_text.replace('|',' ')
    clean_text = clean_text.replace(':',' ')

    # Replace w/ nothing
    clean_text = clean_text.replace('?','')

    # Ensures there's only ever at most single space characters seperating everything 
    clean_text = " ".join(clean_text.split())

    return clean_text

# Saves data to CSV
def SaveDataToCSV(rows, cols, filename):
    # Ensure the filename has a .csv extenstion if it doesn't already
    if filename[-4:] != ".csv":
        filename = filename + ".csv"
    df = pd.DataFrame(rows, columns = cols) # index = false removes the index col from the data
    df.to_csv(filename)

# Gets the soup version of a webpage from a passed url string
def order_soup(url):
    ### I was getting an error trying to call the url about a messed up SSL cert, and this context is turning off the security to
    ### fix the bug. As asuch this should probably be removed at some point
    context = ssl._create_unverified_context()
    html = urlopen(url,context=context)
    soup = BeautifulSoup(html, features="html.parser")
    return soup

if __name__ == "__main__":
    
    # Pass get_bpa_data a directory if given on the cli, else just run it w/ the default dir
    if sys.argv[1]:
        dir = sys.argv[1]
        dir = dir.replace('\\','\\\\')
        get_bpa_data(directory=dir)
    else:
        get_bpa_data()