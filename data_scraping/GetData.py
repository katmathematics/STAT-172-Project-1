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


# import for counting the rows real quick
import glob 

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

# Gets data about storms from the national centers for environmental information
def get_ncei_data(directory="data\\web_data\\ncei_data"):
    START_YEAR_NCEI = 1986
    BASE_URL_NCEI = "https://www.ncei.noaa.gov/pub/data/swdi/database-csv/v2/"
    RETRIEVE_FILE_ROOT = "nldn-tiles-"

    # Keeps the loop end at the current year 
    cur_year = datetime.date.today().year

    # Loops through all the available years on the BPA website to accquire all the data
    for year in range(START_YEAR_NCEI,cur_year):
        retrieve_file = RETRIEVE_FILE_ROOT + str(year) + ".csv.gz"
        url = BASE_URL_NCEI + retrieve_file
        path, headers = urlretrieve(url, retrieve_file)

        print(headers)
        print(path)

        with gzip.open(retrieve_file) as f:
            lines = f.readlines()
            # move file pointer to the beginning of a file
            #f.seek(0)
            #f = f.writelines(lines[1:])

            data = lines[2:]

            data = [str(row).strip('\\n\'\n') for row in data]
            data = [str(row).lstrip('b\'') for row in data]

            clean_data = [str(row).split(',') for row in data]
            #print(f.readlines())
            #features_train = pd.read_csv(data, on_bad_lines='skip')
            data_headers = clean_data[0]
            data = clean_data[1:]

            new_file_name = RETRIEVE_FILE.rstrip(".gz")
            dir = AppendDir(new_file_name,"data\\web_data\\ncei_data")
            SaveDataToCSV(data,data_headers,dir)
        os.remove(path)
    return "NCEI Data was accquired successfully!"

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


def CSV_Count():
    # use glob to get all the csv files  
    # in the folder 
    csv_files = glob.glob(os.path.join(os.pardir, "data\\web_data\\*.csv")) 
    
    avg_rows = 0;
    counter = 0;

    row_count_log = []
    title_log = []

    customer_ser = 0
    transmission_line = 0
    transformer_inter = 0

    # loop over the list of csv files 
    for f in csv_files: 
        
        # read the csv file 
        df = pd.read_csv(f) 
        
        # print the location and filename 
        #print('File Name:', f.split("\\")[-1]) 
        
        # print the content 
        #print('Row Count:') 
        #print(df.shape[0])
        #print() 

        avg_rows += df.shape[0]
        counter += 1
        
        title_log.append(f.split("\\")[-1])
        row_count_log.append(df.shape[0])

        name =  f.split("\\")[-1]
        if "customer_service" in name:
            customer_ser += df.shape[0]
        elif "transformer_interruptions" in name:
            transformer_inter += df.shape[0]
        elif "transmission_line" in name:
            transmission_line += df.shape[0]
    


    print("Total Row Count: ")
    print(avg_rows)
    #print("Avg Row Count: ")
    #print(avg_rows/counter)
    print("Rows in Customer Service: ")
    print(customer_ser)
    print("Rows in Transformer Interruptions: ")
    print(transformer_inter)
    print("Rows in Transmission Line: ")
    print(transmission_line)

    row_count_log = [row_count_log]
    df = pd.DataFrame(row_count_log, columns = title_log) # index = false removes the index col from the data
    df.to_csv("Row_Counts_In_Each_Table.csv")

if __name__ == "__main__":
    
    #get_ncei_data()
    #CSV_Count()
    # Pass get_bpa_data a directory if given on the cli, else just run it w/ the default dir
    #if len(sys.argv) > 1:
    #    dir = sys.argv[1]
    #    dir = dir.replace('\\','\\\\')
    #    get_bpa_data(directory=dir)
    #else:
    #    get_bpa_data()

    print("Done!")