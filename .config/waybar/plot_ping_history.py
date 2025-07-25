import pandas as pd
import plotly.graph_objects as go
import webbrowser
import os
from datetime import datetime, time

# Load the data
file_path = '/home/pera/.config/waybar/ping_history.csv'
df = pd.read_csv(file_path)

# Convert 'date' column to datetime objects
df['datetime'] = pd.to_datetime(df['date'], format='%Y-%m-%d_%H:%M:%S')

# Drop rows where 'datetime' conversion failed (resulting in NaT)
df.dropna(subset=['datetime'], inplace=True)

# Extract date
df['date_only'] = df['datetime'].dt.date

# Get the current date to use as a reference for the 24h axis
ref_date = datetime.now().date()
current_date = ref_date

# Create a figure
fig = go.Figure()

# Get unique dates and sort them
unique_dates = sorted(df['date_only'].unique())

for date in unique_dates:
    date_df = df[df['date_only'] == date].sort_values(by='datetime').reset_index(drop=True)

    # --- Gap detection logic ---
    # Calculate time difference from the previous point
    time_diff = date_df['datetime'].diff()

    # Identify gaps larger than 1 minute
    gap_threshold = pd.Timedelta(minutes=1)
    gap_indices = time_diff[time_diff > gap_threshold].index

    new_rows = []
    if not gap_indices.empty:
        for i in gap_indices:
            # Get the datetime of the point before the gap
            prev_datetime = date_df.loc[i - 1, 'datetime']
            # Create a new point with a NaN value just after the previous point to create a break in the line
            nan_time = prev_datetime + pd.Timedelta(seconds=1)
            new_rows.append({'datetime': nan_time, 'ping_ms': None, 'date_only': date})

    # Combine original data with new gap rows
    if new_rows:
        gaps_df = pd.DataFrame(new_rows)
        plot_df = pd.concat([date_df, gaps_df]).sort_values(by='datetime').reset_index(drop=True)
    else:
        plot_df = date_df
    # --- End of gap detection logic ---

    # Map all datetimes to a single reference date to overlay them on a 24h axis
    plot_df['plot_time'] = plot_df['datetime'].apply(lambda dt: datetime.combine(ref_date, dt.time()) if pd.notna(dt) else None)
    
    # Set opacity for current day's plot
    opacity = 0.7 if date == current_date else 0.3
    
    fig.add_trace(go.Scatter(
        x=plot_df['plot_time'],
        y=plot_df['ping_ms'],
        mode='markers',
        name=str(date),
        opacity=opacity,
        connectgaps=False  # This ensures that NaN values create gaps in the line
    ))

# Update layout for a fixed 24-hour X-axis
fig.update_layout(
    title='Ping History',
    template="plotly_dark",
    xaxis_title='Time',
    yaxis_title='Ping (ms)',
    legend_title='Date',
    xaxis=dict(
        range=[datetime.combine(ref_date, time.min), datetime.combine(ref_date, time.max)],
        tickformat='%H:%M:%S',  # Format x-axis labels to show time
    ),
   shapes=[
        # RED ZONE (bottom layer, drawn first)
        # Covers the entire area from 200ms upwards
       dict(
            type="rect",
            xref="paper", yref="y",
            x0=0, x1=1,
            y0=200, y1=1000, 
            fillcolor="red",
            opacity=0.1,
            layer="below",
            line_width=0,
        ), 
        # YELLOW ZONE (middle layer, drawn on top of red)
        # Covers the area from 100ms to 200ms
        dict(
            type="rect",
            xref="paper", yref="y",
            x0=0, x1=1,
            y0=100, y1=200,
            fillcolor="yellow",
            opacity=0.1,
            layer="below",
            line_width=0,
        ),
        # GREEN ZONE (top layer, drawn on top of everything else)
        # Covers the area from 0ms to 100ms
        dict(
            type="rect",
            xref="paper", yref="y",
            x0=0, x1=1,
            y0=0, y1=100,
            fillcolor="green",
            opacity=0.1,
            layer="below",
            line_width=0,
        ),
    ] 
)

# Write to HTML and open in browser
plot_file = '/home/pera/.config/waybar/ping_plot.html'
fig.write_html(plot_file)

webbrowser.open('file://' + os.path.realpath(plot_file))
