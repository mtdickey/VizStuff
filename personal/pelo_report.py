# -*- coding: utf-8 -*-
"""
Created on Fri Oct 23 17:18:20 2020

@author: mtdic
"""

### Load modules
import numpy as np
import pandas as pd
import seaborn as sns
from datetime import datetime
import matplotlib.pyplot as plt
from peloton import PelotonWorkout #https://github.com/geudrik/peloton-client-library

def power_zone_plot(ride, path, ftp):
    """
    Create a plot of output throughout a power zone workout to analyze how well
    the athlete stayed in the zones throughout the workout.

    Parameters
    ----------
    ride : PelotonWorkout
        PelotonWorkout object containing a Power Zone ride.
    path : str
        Filepath to save the resulting plot.
    ftp : float
        FTP at the time of the ride.  Determines power zone ranges.

    Returns
    -------
    None. Saves a PNG plot to the "plt/power_zone" folder with the provided name and workout date.
    """

    ## Gather the time series data
    if 'output' in dir(ride.metrics):
        output_ts = ride.metrics.output.values
        
        ## Plot the timeseries and add X marks every 5 minutes
        plt.figure(figsize=(12,8))
        plt.plot(range(len(output_ts)), output_ts, linewidth = 2, color = '#1a1a1a')
        xticks = [i for i in range(len(output_ts)) if i%300 == 0]
        xtick_labels = [f"{int(i/300)*5}:00" for i in range(len(output_ts)) if i%300 == 0]
        plt.xticks(xticks, labels = xtick_labels)
        
        ### Set the background color and annotate each zone
        ## Upper limit is nearest multiple of 100 above FTP*1.5
        upper_lim = int(np.ceil(ftp*1.5 / 100.0))*100
        plt.ylim([0, upper_lim])
        plt.axhspan(np.round(ftp*1.5), upper_lim, facecolor ='#e31a1c', alpha = 0.5)
        plt.text(-5, upper_lim-15, f"Zone 7 (>{int(np.round(ftp*1.5))})")
        plt.axhspan(np.round(ftp*1.2), np.round(ftp*1.5), facecolor ='#f16913', alpha = 0.5) 
        plt.text(-5, np.round(ftp*1.5)-15, f"Zone 6 ({int(np.round(ftp*1.5))})")
        plt.axhspan(np.round(ftp*1.05), np.round(ftp*1.2), facecolor ='#fec44f', alpha = 0.5) 
        plt.text(-5, np.round(ftp*1.2)-15, f"Zone 5 ({int(np.round(ftp*1.2))})")
        plt.axhspan(np.round(ftp*0.90), np.round(ftp*1.05), facecolor ='#fee090', alpha = 0.5) 
        plt.text(-5, np.round(ftp*1.05)-15, f"Zone 4 ({int(np.round(ftp*1.05))})")
        plt.axhspan(np.round(ftp*0.75), np.round(ftp*0.9), facecolor ='#d9ef8b', alpha = 0.5) 
        plt.text(-5, np.round(ftp*0.9)-15, f"Zone 3 ({int(np.round(ftp*0.9))})")
        plt.axhspan(np.round(ftp*0.55), np.round(ftp*0.75), facecolor ='#abd9e9', alpha = 0.5) 
        plt.text(-5, np.round(ftp*0.75)-15, f"Zone 2 ({int(np.round(ftp*0.75))})")
        plt.axhspan(0, np.round(ftp*0.55), facecolor ='#d8daeb', alpha = 0.5) 
        plt.text(-5, 25, f"Zone 1 ({int(np.round(ftp*0.55))})")
        
        ## Add a title and save
        plt.title(f"{ride.ride.title} with {ride.ride.instructor.name} \n{ride.start_time.strftime('%Y-%m-%d')}")
        plt.savefig(path, bbox_inches='tight')
        plt.close()


def ftp_trend_chart(rides):
    """
    Plots the trend of FTP over time based on the user's FTP test rides and output.

    Parameters
    ----------
    rides : list(PelotonWorkout)
        List of PelotonWorkout objects that are cycling rides.

    Returns
    -------
    list, list.
      - First list is a list of datetime objects representing when the test was taken
      - Second list is a list of floats representing the FTP result.
      Also saves a PNG plot to the "plt" folder with the provided name and today's date.

    """
    ## Find the FTP Test rides, calculate result, and gather dates
    ftp_rides = [p for p in rides if 'FTP Test' in p.ride.title and 'Warm Up' not in p.ride.title]
    if len(ftp_rides) > 1:
        dates = []
        ftps = []
        for r in ftp_rides:
            ## FTP is Average output, discounted 5%
            output_list = r.metrics.output.values
            ftp = np.mean(output_list)-0.05*np.mean(output_list)
            ftps.append(ftp)
            
            ## Get the date of the workout
            dates.append(r.start_time)
        
        ## Make and save a plot
        plt.figure(figsize=(10,6))
        plt.plot(dates, ftps, '--bo', color='#737373', linewidth=3,
                 marker='h', markerfacecolor='#3182bd', markeredgewidth=2, markeredgecolor='black',
                 markersize=10)
        plt.xticks(dates, rotation=30, fontsize=10)
        plt.title(f'FTP Over Time for {name}')
        plt.ylabel('FTP')
        plt.savefig(f"plts/{name}_ftp_trend_{datetime.today().strftime('%Y-%m-%d')}.png",
                    bbox_inches='tight')
        plt.close()
        
        return dates, ftps
    else:
        print(f"No FTP rides for {name}")
        return None, None


def instructor_barchart(rides):
    """
    Make a barchart of the top Peloton instructors for the user's cycling workouts.
    
    Parameters
    ----------
    rides : list(PelotonWorkout)
        List of PelotonWorkout objects that are cycling rides.

    Returns
    -------
    None. Saves a PNG plot to the "plt" folder with the provided name and today's date.
    """
    
    ## Get a list of instructors for the rides
    instructors = []
    for ride in rides:
        instructors.append(ride.ride.instructor.name)
    
    ## Make the plot
    plt.style.use('fivethirtyeight')
    plt.figure(figsize=(12,8))
    barchart = pd.Series(instructors).value_counts().sort_values().plot(kind='barh')
    barchart.set_title(f'Top Instructors for {name}')
    barchart.set_xlabel('Rides')
    fig = barchart.get_figure()
    fig.savefig(f"plts/{name}_instructors_{datetime.today().strftime('%Y-%m-%d')}.png",
                bbox_inches='tight')
    plt.close()



def distance_histogram(distances):
    """

    Parameters
    ----------
    distances : list(float)
        Distances gathered from Peloton cycling workouts.

    Returns
    -------
    None.  Saves a PNG plot to the "plt" folder with the provided name and today's date.
    """

    plt.style.use('fivethirtyeight')
    plt.figure(figsize=(10,6))
    hist = (sns.histplot(distances, kde=True))
    hist.set_title(f"Distribution of Peloton Ride Distances\n{name}'s "+ 
                         f"{len(cycling_rides)} Rides")
    hist.set_xlabel("Distance (miles)")
    fig = hist.get_figure()
    fig.savefig(f"plts/{name}_distance_hist_{datetime.today().strftime('%Y-%m-%d')}.png",
                bbox_inches='tight')
    plt.close()


def main():
    """
    Run the above functions to generate a Peloton report for the user.
    
    Returns
    -------
    None.

    """
    
    ## Take user input for the name of whomever's login in is provided
    name = input('Provide name of user currently saved in ".config/peloton": ')
    
    ## Load all of the workouts and get the cycling rides for this report
    workouts = PelotonWorkout.list()
    cycling_rides = [p for p in workouts if p.fitness_discipline == 'cycling']
    
    ## Calculate total distance of all rides
    distances = []
    for ride in cycling_rides:
        if "distance_summary" in dir(ride.metrics):
            miles = ride.metrics.distance_summary.value
            if miles is not None:
                distances.append(miles)
    print(f"{name} has biked {np.sum(distances):,} miles through {len(cycling_rides)} Peloton rides " +
          f"({len(cycling_rides) - len(distances)} are missing distances).")
    
    ## Save a histogram of the distances
    distance_histogram(distances)
    
    ## Save a barchart of instructors
    instructor_barchart(cycling_rides)
    
    ## Save a linechart with the trend of FTP test results over time (if any)
    dates, ftps = ftp_trend_chart(cycling_rides)
    ftp_df = pd.DataFrame({'date': dates, 'ftp': ftps})
    
    ## Save any PowerZone plots that haven't been saved yet
    if (ftps is not None) and (dates is not None):
        pzone_rides = pzone_rides = [p for p in cycling_rides if 'Power Zone' in p.ride.title]
        if len(pzone_rides) > 0:
            for r in pzone_rides:
                ride_date = r.start_time.strftime("%Y-%m-%d")
                ride_title = r.ride.title.lower().replace(' ', '_')
                path = f"plts/power_zone/{name}_{ride_title}_{ride_date}.png"
                if not os.path.exists(path):
                    ## Determine FTP based on FTP results and dates returned by ftp_trend_chart
                    if r.start_time < min(ftp_df['date']):
                        ## Take earliest FTP result for any rides before the 1st test
                        ftp = ftp_df['ftp'][ftp_df['date'].argmin()]
                    else:
                        ## Otherwise, take most recent FTP before the ride
                        ftp_sub_df = ftp_df[ftp_df['date'] <= r.start_time].copy().reset_index()
                        ftp = ftp_sub_df['ftp'][ftp_sub_df['date'].argmax()]
                    power_zone_plot(r, path = path, ftp = ftp)

if __name__ == "__main__":
    main()
    
