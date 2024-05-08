###
# Authors: Katja Mathesius
# Description: Contains the helper functions for GetData.py
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

# Appends the desired directory to the filename
def AppendDir(filename,directory="data\\web_data"):
    # Makes the directory to be written to if it doesn't already exist
    if not os.path.exists(os.path.join(directory)):
        os.makedirs(os.path.join(directory))


    partial_loc = directory + "\\" + filename
    full_loc = os.path.join(partial_loc)
    
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


def CSV_Count(directory="data\\web_data\\*.csv"):
    # use glob to get all the csv files  
    # in the folder 
    csv_files = glob.glob(os.path.join(os.pardir, directory)) 
    
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
