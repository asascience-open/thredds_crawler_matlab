# THREDDS Crawler for Matlab
A simple Matlab based THREDDS (TDS) catalog crawler. Parses TDS catalog records in to a matlab data structure

Connected with work conducted on the [python based thredds crawler](https://github.com/asascience-open/thredds_crawler)

### Usage:
In a MATLAB command window type:

```
datasets = crawl_thredds;
```

### Optional Inputs

* url = URL to the thredds data server you'd like to crawl (FRF waves by default)
* extension = extension of data files you want to open (.nc by default)

### Output

* data = Matlab structure the following fields:
  * id - Dataset ID
  * name - Dataset name
  * catalog_url - Dataset url

### Coming Soon:
* Logging
* Downloading datasets
* Harvesting metadata