###
# Authors: Katja Mathesius
# Description: Scrapes the Web for Data
###

from bs4 import BeautifulSoup # For scraping data from web contents
from urllib.request import urlopen # For grabbing data from the web
import datetime # For data that can reliably be grabbed up to a current data, this is used to keep the date current
import pandas as pd # For saving data to a csv format

# Collects data from the Bonneville Power Administration website
def get_bpa_data(merge_tables=False):

    START_YEAR_BPA = 1999
    BASE_URL_BPA = "https://transmission.bpa.gov/Business/Operations/Outages/OutagesCY"

    # Keeps the loop end at the current year 
    cur_year = datetime.date.today().year

    for year in range(START_YEAR_BPA,START_YEAR_BPA+1):
        url = BASE_URL_BPA + str(year) + ".htm"
        bpa_soup = order_soup(url)

        tables = []
        for label in bpa_soup.find_all("div", class_ = "tablelabel"):
            print(label.get_text)
            values = []
            for sibling in label.find_next_siblings():
                if sibling.name == "tablelabel":  # iterate through siblings until separator is encoutnered
                    break
                values.append(sibling)
            tables.append(values)

        for table in tables:
            # We create a table for each year, and then merge them all at the end if desired to prevent any issues arising from 
            # different years having different headers
            table_header_html = table.find_all('th')
            tables_headers = []
            for header in table_header_html:
                tables_headers.append(header.get_text())
        
            table_row_html = bpa_soup.find_all('tr')
            tables_rows = []
            for row_html in table_row_html:
                row = []
                for data in row_html.find_all('td'):
                    row.append(data.get_text())
                tables_rows.append(row)  
            
            


            
        
    return "BPA data was accquired successfully!"

#
def SaveData(rows, cols, filename):
    # Ensure the filename has a .csv extenstion if it doesn't already
    if filename[-4:] != ".csv":
        filename = filename + ".csv"
    df = pd.DataFrame(rows, columns = cols)
    df.to_csv(filename)

# Gets the soup version of a webpage from a passed url string
def order_soup(url):
    html = urlopen(url).read()
    soup = BeautifulSoup(html, features="html.parser")
    return soup

if __name__ == "__main__":
    print(get_bpa_data())