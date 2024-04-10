###
# Authors: Katja Mathesius
# Description: Scrapes the Web for Data
###

from bs4 import BeautifulSoup # For scraping data from web contents
from urllib.request import urlopen # For grabbing data from the web
from urllib.request import urlretrieve # For grabbing data from the web
import ssl # For fixing a connection issue w/ the web scraper
import datetime # For data that can reliably be grabbed up to a current data, this is used to keep the date current
import pandas as pd # For saving data to a csv format
import re # For file
import os # For saving the file to a specific directory
import sys # For taking variables from the command line
import gzip # For unzipping gzip
from DataHelper import *

# import for counting the rows real quick
import glob 

# Collects data from the Bonneville Power Administration website
def get_bpa_data(directory="data\\web_data\\bpa_data"):

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

# Gets data about storms from the national centers for environmental information about lightning strikes
def get_ncei_data(directory="data\\web_data\\ncei_data"):
    START_YEAR_NCEI = 1990
    BASE_URL_NCEI = "https://www.ncei.noaa.gov/pub/data/swdi/database-csv/v2/"
    RETRIEVE_FILE_ROOT = "nldn-tiles-"

    # Keeps the loop end at the current year 
    cur_year = datetime.date.today().year

    # Loops through all the available years on the BPA website to accquire all the data
    for year in range(START_YEAR_NCEI,cur_year):
        retrieve_file = RETRIEVE_FILE_ROOT + str(year) + ".csv.gz"
        url = BASE_URL_NCEI + retrieve_file
        dir_retrieve_file = AppendDir(retrieve_file,directory)
        path, headers = urlretrieve(url, dir_retrieve_file)

        with gzip.open(path) as f:
            lines = f.readlines()

            data = lines[2:]

            data = [str(row).strip('\\n\'\n') for row in data]
            data = [str(row).lstrip('b\'') for row in data]

            clean_data = [str(row).split(',') for row in data]
            #print(f.readlines())
            #features_train = pd.read_csv(data, on_bad_lines='skip')
            data_headers = clean_data[0]
            data = clean_data[1:]

            new_file_name = retrieve_file.rstrip(".gz")
            dir = AppendDir(new_file_name,"data\\web_data\\ncei_data")
            SaveDataToCSV(data,data_headers,dir)
        os.remove(path)
    return "NCEI Data was accquired successfully!"

if __name__ == "__main__":
    
    # Pass get_bpa_data a directory if given on the cli, else just run it w/ the default dir
    if len(sys.argv) > 1:
        func_select = sys.argv[1]
        if func_select == "bpa":
            if len(sys.argv) > 2:
                dir = sys.argv[2]
                dir = dir.replace('\\','\\\\')
                get_bpa_data(directory=dir)
            else:
                get_bpa_data()
        elif func_select == "ncei":
            if len(sys.argv) > 2:
                dir = sys.argv[2]
                dir = dir.replace('\\','\\\\')
                get_ncei_data(directory=dir)
            else:
                get_ncei_data()
    else:
        get_bpa_data()
        get_ncei_data()
        
    print("Done!")