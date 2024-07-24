# # conda create -n dash_test -c conda-forge python=3.9 plotly dash pandas dash-bootstrap-components dash-bootstrap-templates dash-ag-grid -y
import datetime
import pandas as pd

import dash_ag_grid as dag
import dash_bootstrap_components as dbc
#from dash_bootstrap_templates import load_figure_template
from dash import Dash, Input, Output, State, html, dcc, callback, no_update, ctx #, clientside_callback

from plotly import data
# adds  templates to plotly.io (for color switcher)
#load_figure_template(["minty", "minty_dark"])


app = Dash(__name__, external_stylesheets=[dbc.themes.CYBORG, dbc.icons.FONT_AWESOME], suppress_callback_exceptions=True)

df = data.election()

# color_mode_switch =  html.Span(
#     [
#         dbc.Label(className="fa fa-moon", html_for="color-mode-switch"),
#         dbc.Switch( id="color-mode-switch", value=False, className="d-inline-block ms-1", persistence=True),
#         dbc.Label(className="fa fa-sun", html_for="color-mode-switch"),
#     ]
# )

columnDefs = [
    {"field": "district",
     "rowDrag": True,
     "checkboxSelection": True,
    },
    {"field": "total",
     "filter": "agNumberColumnFilter"},
    {"field": "winner"},
    {"field": "result"},
]

defaultColDef = {
    "filter": True,
    "floatingFilter": True,
    "resizable": True,
    "sortable": True,
    "editable": True,
    "minWidth": 150,
}

active_table = dag.AgGrid(
            id="active-data-grid",
            columnSize="sizeToFit",
            columnDefs=columnDefs,
            defaultColDef=defaultColDef,
            rowData=df.to_dict("records"),
            csvExportParams={
                "fileName": f"active_{datetime.datetime.today().strftime('%Y-%m-%d')}.csv",
            },
            className='ag-theme-material-dark',
            dashGridOptions={"rowSelection": 'multiple',
                             "rowMultiSelectWithClick":True},
            persistence=True,
            persisted_props=['rowData', 'virtualData']
        )

inactive_table = dag.AgGrid(
            id="inactive-data-grid",
            columnSize="sizeToFit",
            columnDefs=columnDefs,
            defaultColDef=defaultColDef,
            rowData=pd.DataFrame().to_dict("records"),
            csvExportParams={
                "fileName": f"inactive_{datetime.datetime.today().strftime('%Y-%m-%d')}.csv",
            },
            className='ag-theme-material-dark',
            dashGridOptions={"rowSelection": 'multiple',
                             "rowMultiSelectWithClick":True},
            persistence=True,
            persisted_props=['rowData', 'virtualData']
        )


app.layout = html.Div(
    [
        html.H2(["Test of Dash Features"]),
        #color_mode_switch,
        dcc.Markdown(
            "Use the slider to control the multiplier."
        ),
        html.H5('Discount rate:'),
        html.Div(
            dcc.Slider(3, 7, 0.01, value=5.55, id='multiplier-slider', 
                   marks={3: "3%", 4: "4%", 5: "5%", 6: "6%", 7: "7%"}, tooltip={"always_visible": True, "template": "{value}%"}),
            style={'width':'50%'}
        ),
        html.Br(),
        html.H4('Active Districts Table'),
        html.Br(),
        dbc.Row(children=[
            dbc.Col([dbc.Card([dbc.CardBody([html.H2(id='number-of-records-card'), html.P("Number of Active Districts")])])]), 
            dbc.Col([dbc.Card([dbc.CardBody([html.H2(id='sum-of-column-card'), html.P("Total Active Votes")])])])
            ]
        ),
        html.Br(),
        html.Button("Download CSV", id="active-csv-button", n_clicks=0),
        active_table,
        html.Span([
                  dbc.Button(
                      id="move-row-btn",
                      children="Mark District Inactive",
                      color="success",
                      size="md",
                      className='mt-3 me-1'
                    ),
                    dbc.Button(
                      id="add-row-btn",
                      children="Add New Case",
                      color="primary",
                      size="md",
                      className='mt-3'
                  ),
        ]),
        html.Br(),
        html.Br(),
        html.H4('Inactive Districts Table'),
        html.Br(),
        dbc.Row(children=[
            dbc.Col([dbc.Card([dbc.CardBody([html.H2(id='number-of-inactive-records-card'), html.P("Number of Inactive Districts")])])]), 
            dbc.Col([dbc.Card([dbc.CardBody([html.H2(id='sum-of-inactive-column-card'), html.P("Total Inactive Votes")])])])
            ]
        ),
        html.Br(),
        html.Button("Download CSV", id="inactive-csv-button", n_clicks=0),
        inactive_table,
        html.Span([
                  dbc.Button(
                      id="move-inactive-row-btn",
                      children="Mark District Active",
                      color="success",
                      size="md",
                      className='mt-3 me-1'
                    ),
                    dbc.Button(
                      id="add-inactive-row-btn",
                      children="Add New Case",
                      color="primary",
                      size="md",
                      className='mt-3'
                  ),
        ])
    ]
)

@callback(
    Output("number-of-records-card", "children"),
    Input("active-data-grid", "virtualRowData"),
    Input("active-data-grid", "cellValueChanged")
)
def update_number_of_records_card(virtual_data, values_changed):
    if virtual_data is not None:
        return str(len(virtual_data))
    else:
        return ''


@callback(
    Output("sum-of-column-card", "children"),
    Input("active-data-grid", "virtualRowData"),
    Input("multiplier-slider", 'value'),
    Input("active-data-grid", "cellValueChanged")
)
def update_total_card(virtual_data, multiplier, values_changed):
    if virtual_data is not None:
        df = pd.DataFrame(virtual_data)
        return str(df['total'].sum()*multiplier/100)
    else:
        return ''

@callback(
    Output("number-of-inactive-records-card", "children"),
    Input("inactive-data-grid", "virtualRowData"),
    Input("inactive-data-grid", "cellValueChanged")
)
def update_number_of_inactive_records_card(virtual_data, values_changed):
    if virtual_data is not None:
        return str(len(virtual_data))
    else:
        return ''


@callback(
    Output("sum-of-inactive-column-card", "children"),
    Input("inactive-data-grid", "virtualRowData"),
    Input("multiplier-slider", 'value'),
    Input("inactive-data-grid", "cellValueChanged")
)
def update_inactive_total_card(virtual_data, multiplier, values_changed):
    if virtual_data is not None:
        df = pd.DataFrame(virtual_data)
        if 'total' in df.columns:
            return str(df['total'].sum()*multiplier/100)
        else:
            return '0'
    else:
        return ''


# add or delete rows of table
@app.callback(
    Output("active-data-grid", "deleteSelectedRows", allow_duplicate=True),
    Output("active-data-grid", "rowData", allow_duplicate=True),
    Output("inactive-data-grid", "rowData", allow_duplicate=True),
    Output("active-data-grid", "virtualRowData", allow_duplicate=True),
    Output("inactive-data-grid", "virtualRowData", allow_duplicate=True),
    Input("move-row-btn", "n_clicks"),
    Input("add-row-btn", "n_clicks"),
    State("active-data-grid", "rowData"),
    State("active-data-grid", "virtualRowData"),
    Input("active-data-grid", "selectedRows"),
    State("inactive-data-grid", "rowData"),
    State("inactive-data-grid", "virtualRowData"),
    prevent_initial_call=True,
)
def update_tables_active_buttons(n_move, n_add, active_data, virtual_active_data, selected_active_data, inactive_data, virtual_inactive_data):
    if ctx.triggered_id == "add-row-btn":
        new_row = {
            "district": [""],
            "total": [0],
            "winner": [""],
            "result": [""]
        }
        df_new_row = pd.DataFrame(new_row)
        updated_table = pd.concat([pd.DataFrame(active_data), df_new_row])
        updated_virtual_table = pd.concat([pd.DataFrame(virtual_active_data), df_new_row])
        return False, updated_table.to_dict("records"), no_update, updated_virtual_table.to_dict("records"), no_update
    elif ctx.triggered_id == "move-row-btn":
        df_selected_active = pd.DataFrame(selected_active_data)
        updated_inactive_table = pd.concat([pd.DataFrame(inactive_data), df_selected_active])
        updated_inactive_virtual_table = pd.concat([pd.DataFrame(virtual_inactive_data), df_selected_active])
        return True, no_update, updated_inactive_table.to_dict("records"), no_update, updated_inactive_virtual_table.to_dict("records")
    else:
        return False, no_update, no_update, no_update, no_update


# add or delete rows of table
@app.callback(
    Output("inactive-data-grid", "deleteSelectedRows", allow_duplicate=True),
    Output("inactive-data-grid", "rowData", allow_duplicate=True),
    Output("active-data-grid", "rowData", allow_duplicate=True),
    Output("active-data-grid", "virtualRowData", allow_duplicate=True),
    Output("inactive-data-grid", "virtualRowData", allow_duplicate=True),
    Input("move-inactive-row-btn", "n_clicks"),
    Input("add-inactive-row-btn", "n_clicks"),
    State("inactive-data-grid", "rowData"),
    State("inactive-data-grid", "virtualRowData"),
    Input("inactive-data-grid", "selectedRows"),
    State("active-data-grid", "rowData"),
    State("active-data-grid", "virtualRowData"),
    prevent_initial_call=True,
)
def update_tables_inactive_buttons(n_move, n_add, inactive_data, selected_inactive_data, virtual_inactive_data, active_data, virtual_active_data):
    if ctx.triggered_id == "add-inactive-row-btn":
        new_row = {
            "district": [""],
            "total": [0],
            "winner": [""],
            "result": [""]
        }
        df_new_row = pd.DataFrame(new_row)
        updated_table = pd.concat([pd.DataFrame(inactive_data), df_new_row])
        updated_virtual_table = pd.concat([pd.DataFrame(virtual_inactive_data), df_new_row])
        return False, updated_table.to_dict("records"), no_update, no_update, updated_virtual_table.to_dict("records")
    elif ctx.triggered_id == "move-inactive-row-btn":
        df_selected_inactive = pd.DataFrame(selected_inactive_data)
        updated_active_table = pd.concat([pd.DataFrame(active_data), df_selected_inactive])
        updated_active_virtual_table = pd.concat([pd.DataFrame(virtual_active_data), df_selected_inactive])
        return True, no_update, updated_active_table.to_dict("records"), updated_active_virtual_table.to_dict("records"), no_update
    else:
        return False, no_update, no_update, no_update, no_update


@callback(
    Output("active-data-grid", "exportDataAsCsv"),
    Input("active-csv-button", "n_clicks"),
)
def export_active_data_as_csv(n_clicks):
    if n_clicks:
        return True
    return False


@callback(
    Output("inactive-data-grid", "exportDataAsCsv"),
    Input("inactive-csv-button", "n_clicks"),
)
def export_inactive_data_as_csv(n_clicks):
    if n_clicks:
        return True
    return False


# ### Color mode switch
# clientside_callback(
#     """
#     (switchOn) => {
#        document.documentElement.setAttribute('data-bs-theme', switchOn ? 'light' : 'dark');  
#        return window.dash_clientside.no_update
#     }
#     """,
#     Output("color-mode-switch", "id"),
#     Input("color-mode-switch", "value"),
# )

if __name__ == "__main__":
    app.run(debug=True)