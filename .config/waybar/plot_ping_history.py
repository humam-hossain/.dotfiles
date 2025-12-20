import pandas as pd
import plotly.graph_objects as go
import webbrowser
import os
from datetime import datetime, timedelta, time

# --- Configuration ---
FILE_PATH = '~/.config/waybar/ping_history.csv'
GAP_THRESHOLD_SECONDS = 60  # If gap > 60s, consider it offline
BAD_PING = 200
MED_PING = 100
DAYS_TO_SHOW = 30

# --- Custom Palette ---
# Offline: Surface2 (Grey)
COLOR_OFFLINE = '#43433C' 
# Bad: Red (Quality 3)
COLOR_BAD     = '#EB0111' 
# Medium: Yellow (Quality 2)
COLOR_MED     = '#EBD501' 
# Good: Green (Quality 1)
COLOR_GOOD    = '#00EB3A' 
# Background Color for the HTML page (White for Light Theme)
PAGE_BG_COLOR = '#ffffff'
# Text Color for the HTML page (Black for Light Theme)
PAGE_TEXT_COLOR = '#000000'

def get_quality(ping):
    """
    Maps ping to quality integer:
    Good (<100ms)  -> 1
    Med (100-200ms) -> 2
    Bad (>200ms)   -> 3
    """
    if pd.isna(ping): return None
    if ping >= BAD_PING: return 3
    if ping >= MED_PING: return 2
    return 1

def get_color_by_quality(quality):
    if quality == 3: return COLOR_BAD
    if quality == 2: return COLOR_MED
    if quality == 1: return COLOR_GOOD
    return COLOR_OFFLINE

def create_figure_for_day(date_obj, day_df):
    """Creates a single Plotly figure for a specific date."""
    
    # 1. Setup Data & Shapes
    shapes = []
    
    # Define the start/end of this day for axis locking (00:00 - 23:59)
    start_of_day = datetime.combine(date_obj, time.min)
    end_of_day   = datetime.combine(date_obj, time.max)
    
    if not day_df.empty:
        day_df = day_df.sort_values('datetime').reset_index(drop=True)
        day_df['quality'] = day_df['ping_ms'].apply(get_quality)
        day_df['color'] = day_df['quality'].apply(get_color_by_quality)

        # --- Shape Generation Logic ---
        curr_quality = day_df.iloc[0]['quality']
        seg_start_time = day_df.iloc[0]['datetime']
        prev_time = day_df.iloc[0]['datetime']
        
        for j in range(1, len(day_df)):
            row = day_df.iloc[j]
            curr_time = row['datetime']
            new_quality = row['quality']
            
            time_diff = (curr_time - prev_time).total_seconds()
            is_gap = time_diff > GAP_THRESHOLD_SECONDS
            
            if is_gap:
                # Close previous segment
                if seg_start_time != prev_time:
                    shapes.append(dict(
                        type="rect",
                        x0=seg_start_time, x1=prev_time, y0=0, y1=4,
                        fillcolor=get_color_by_quality(curr_quality), line_width=0, layer="below"
                    ))
                # Offline segment
                shapes.append(dict(
                    type="rect",
                    x0=prev_time, x1=curr_time, y0=0, y1=4,
                    fillcolor=COLOR_OFFLINE, line_width=0, layer="below"
                ))
                curr_quality = new_quality
                seg_start_time = curr_time
                
            elif new_quality != curr_quality:
                # State change
                shapes.append(dict(
                    type="rect",
                    x0=seg_start_time, x1=curr_time,
                    fillcolor=get_color_by_quality(curr_quality), line_width=0, layer="below"
                ))
                curr_quality = new_quality
                seg_start_time = curr_time
                
            prev_time = curr_time

        # Close last segment
        if seg_start_time != prev_time:
            shapes.append(dict(
                type="rect",
                x0=seg_start_time, x1=prev_time, y0=0, y1=4,
                fillcolor=get_color_by_quality(curr_quality), line_width=0, layer="below"
            ))

    # 2. Create Figure
    fig = go.Figure()
    
    if not day_df.empty:
        # Invisible Trace for Hover
        fig.add_trace(go.Scatter(
            x=day_df['datetime'],
            y=day_df['quality'], 
            customdata=day_df['ping_ms'],
            mode='markers',
            opacity=0, 
            marker=dict(color=day_df['color']),
            hovertemplate="<b>%{x|%H:%M:%S}</b><br>Ping: %{customdata}ms<extra></extra>",
            hoverlabel=dict(
                bgcolor=day_df['color'], 
                font=dict(color='black')
            ),
            name='Quality',
            showlegend=False
        ))
    else:
        # Add a dummy invisible trace just to establish the time range for empty days
        fig.add_trace(go.Scatter(
            x=[start_of_day, end_of_day],
            y=[0, 0],
            mode='markers', opacity=0, hoverinfo='skip'
        ))

    # 3. Configure Layout
    fig.update_layout(
        title=dict(
            text=date_obj.strftime('%A, %b %d'),
            x=0.01, # Left align title
            font=dict(size=14, color='#333333') # Dark grey for title
        ),
        template="plotly_white", # Light theme
        height=180, # Height per plot
        hovermode='x',
        margin=dict(l=20, r=20, t=40, b=20),
        xaxis=dict(
            range=[start_of_day, end_of_day],
            tickformat='%H:%M',
            showgrid=False,
            showspikes=True, spikemode='across', spikesnap='cursor', 
            spikecolor='black', spikethickness=1, spikedash='solid', # Black spike line
        ),
        yaxis=dict(
            visible=False, fixedrange=True, range=[0, 4]
        ),
        shapes=shapes,
        paper_bgcolor=PAGE_BG_COLOR,
        plot_bgcolor=PAGE_BG_COLOR
    )
    
    return fig

def main():
    # 1. Load Data
    expanded_path = os.path.expanduser(FILE_PATH)
    if not os.path.exists(expanded_path):
        print(f"File not found: {expanded_path}")
        return

    df = pd.read_csv(expanded_path)
    df['datetime'] = pd.to_datetime(df['date'], format='%Y-%m-%d_%H:%M:%S', errors='coerce')
    df.dropna(subset=['datetime'], inplace=True)
    
    # 2. Determine Date Range
    today = datetime.now().date()
    target_dates = [today - timedelta(days=i) for i in range(DAYS_TO_SHOW)]
    
    # 3. Generate HTML Content
    output_file = os.path.expanduser('~/.config/waybar/ping_plot.html')
    
    with open(output_file, 'w') as f:
        # Start HTML structure with light background
        f.write(f"""
        <html>
        <head>
            <title>Ping History</title>
            <style>
                body {{ background-color: {PAGE_BG_COLOR}; color: {PAGE_TEXT_COLOR}; font-family: sans-serif; margin: 20px; }}
            </style>
        </head>
        <body>
            <h2 style="text-align: center;">Ping History (Last {DAYS_TO_SHOW} Days)</h2>
        """)
        
        for i, date_obj in enumerate(target_dates):
            print(f"Generating plot for day_{i} ...")
            # Filter data for this date
            day_df = df[df['datetime'].dt.date == date_obj].copy()
            
            # Create separate figure
            fig = create_figure_for_day(date_obj, day_df)
            
            # Generate HTML for this figure
            # Include plotly.js only in the first figure
            plot_html = fig.to_html(full_html=False, include_plotlyjs='cdn' if i == 0 else False)
            f.write(f"<div style='margin-bottom: 20px;'>{plot_html}</div>")

        f.write("</body></html>")

    webbrowser.open('file://' + os.path.realpath(output_file))

if __name__ == "__main__":
    main()
