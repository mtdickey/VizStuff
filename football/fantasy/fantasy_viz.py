# -*- coding: utf-8 -*-
"""
Created on Wed Dec  2 18:25:56 2020

@author: mtdic
"""

import re
import pandas as pd
import numpy as np
import matplotlib.pyplot as plt
import seaborn as sns
from espn_api.football import League

from sklearn.linear_model import LinearRegression

from cookies import cookies

### `espn_api` connection
## League cookies
cookie_dict = cookies.cookie_dict

# private league with cookies
league_name = 'athens'
league = League(league_id=cookie_dict[f'{league_name}_league_id'], year=2020,
                espn_s2=cookie_dict['espn_s2'],
                swid=cookie_dict['swid']
                #,debug = True
                )

#%%
## Better approach: Using the API to get the draft
player_ids = []
player_names = []
round_nums = []
round_picks = []
teams = []
for pick in league.draft:
    player_ids.append(pick.playerId)
    player_names.append(pick.playerName)
    round_nums.append(pick.round_num)
    round_picks.append(pick.round_pick)
    teams.append(pick.team)
draft_df = pd.DataFrame({'player_id': player_ids,
                         'player_name': player_names,
                         'round_num': round_nums,
                         'round_pick': round_picks,
                         'team': teams})
draft_df['team_owner'] = draft_df['team'].apply(lambda x: x.owner)
draft_df['team_name'] = draft_df['team'].apply(lambda x: x.team_name)

def get_player_obj(player_id, player_name):
    
    try:
        player = league.player_info(playerId = player_id)
    except:
        try:
            player = league.player_info(name = player_name, playerId = player_id)
        except:
            return None
    
    return player

draft_df['Player_obj'] = draft_df.apply(lambda x: get_player_obj(x['player_id'], x['player_name']), axis = 1)
draft_df['points'] = draft_df['Player_obj'].apply(lambda x: x.stats[0]['points'])
draft_df['position'] = draft_df['Player_obj'].apply(lambda x: x.position)

avg_pos_points = draft_df.groupby('position').agg({'points': np.mean}).sort_values('points', ascending = False).reset_index().rename(columns = {'points':'avg_pos_points'})

draft_df = draft_df.merge(avg_pos_points, on = 'position')
draft_df['points_above_avg'] = draft_df['points'] - draft_df['avg_pos_points']
draft_df['overall_pick'] = (draft_df['round_num']-1)*8+draft_df['round_pick']

sns.regplot(data = draft_df, x = 'overall_pick',
            y = 'points_above_avg')

reg = LinearRegression().fit(np.array(draft_df['overall_pick']).reshape(-1, 1),
                             draft_df['points_above_avg'])

draft_df['preds'] = reg.predict(np.array(draft_df['overall_pick']).reshape(-1, 1))
draft_df['points_above_pred'] = draft_df['points_above_avg'] - draft_df['preds']


biggest_steals = (draft_df.nlargest(10, 'points_above_pred', keep = 'all')
                  .sort_values('points_above_pred'))
plt.figure(figsize=(21,16))
plt.style.use('fivethirtyeight')
ax = biggest_steals.plot(kind='barh', y = 'points_above_pred', x = 'player_name',
                         color='#31a354', legend = None)
ax.set_ylabel('')
plt.yticks(fontsize=7)
plt.xticks(fontsize=10)
plt.show()


biggest_steals_after_1st = (draft_df[draft_df['round_num'] > 1]
                            .nlargest(10, 'points_above_pred', keep = 'all')
                            .sort_values('points_above_pred'))
biggest_steals_after_1st['player_name_short'] = biggest_steals_after_1st['player_name'].apply(lambda x: x[0] + '. ' + x.split(' ')[1] if not x.endswith('D/ST') else x)
biggest_steals_after_1st['owner_name_short'] = biggest_steals_after_1st['team_owner'].apply(lambda x: x[0] + '. ' + x.split(' ')[1])
biggest_steals_after_1st['x_label'] = biggest_steals_after_1st['player_name_short'] + '\n' + biggest_steals_after_1st['owner_name_short'] + ' Pick #' + biggest_steals_after_1st['overall_pick'].astype(str)
plt.figure(figsize=(21,16))
plt.style.use('fivethirtyeight')
ax = biggest_steals_after_1st.plot(kind='barh', y = 'points_above_pred', x = 'x_label',
                                   color='#31a354', legend = None)
ax.set_ylabel('')
ax.set_xlabel('Points Above Avg. Drafted Player at Position', fontsize=10)
plt.yticks(fontsize=7)
plt.xticks(fontsize=10)
plt.title("Biggest Steals after Rd. 1", fontsize=10)
plt.show()


biggest_busts = (draft_df.nsmallest(10, 'points_above_pred', keep = 'all')
                  .sort_values('points_above_pred', ascending = False))
plt.figure(figsize=(21,16))
plt.style.use('fivethirtyeight')
ax = biggest_busts.plot(kind='barh', y = 'points_above_pred', x = 'player_name',
                        color = '#de2d26', legend = None)
ax.set_ylabel('')
plt.yticks(fontsize=7)
plt.xticks(fontsize=10)
plt.show()


biggest_busts_first_2 = (draft_df[draft_df['round_num'] <= 2]
                         .nsmallest(10, 'points_above_pred', keep = 'all')
                         .sort_values('points_above_pred', ascending = False))
biggest_busts_first_2['player_name_short'] = biggest_busts_first_2['player_name'].apply(lambda x: x[0] + '. ' + x.split(' ')[1])
biggest_busts_first_2['owner_name_short'] = biggest_busts_first_2['team_owner'].apply(lambda x: x[0] + '. ' + x.split(' ')[1])
biggest_busts_first_2['x_label'] = biggest_busts_first_2['player_name_short'] + '\n' + biggest_busts_first_2['owner_name_short'] + ' Pick #' + biggest_busts_first_2['overall_pick'].astype(str)
plt.figure(figsize=(21,16))
plt.style.use('fivethirtyeight')
ax = biggest_busts_first_2.plot(kind='barh', y = 'points_above_pred', x = 'x_label',
                                color = '#de2d26', legend = None)
ax.set_ylabel('')
ax.set_xlabel('Points Above Avg. Drafted Player at Position', fontsize=10)
plt.yticks(fontsize=7)
plt.xticks(fontsize=10)
plt.title("Biggest Busts of Rd. 1 and 2", fontsize=10)
plt.show()


WEEKS = range(1,18)
teams = []
players = []
scores = []
week_list = []
for week in WEEKS:
    for box in league.box_scores(week):
        for player in box.home_lineup:
            if player.slot_position != 'BE':
                players.append(player)
                scores.append(player.points)
                teams.append(box.home_team)
                week_list.append(week)
        for player in box.away_lineup:
            if player.slot_position != 'BE':
                players.append(player)
                scores.append(player.points)
                teams.append(box.away_team)
                week_list.append(week)
scoring_df = pd.DataFrame({'team': teams,
                           'player': players,
                           'points': scores,
                           'week': week_list})
scoring_df['player_id'] = scoring_df['player'].apply(lambda x: x.playerId)
scoring_df['player_name'] = scoring_df['player'].apply(lambda x: x.name)
scoring_df['team_name'] = scoring_df['team'].apply(lambda x: x.team_name)
scoring_df['team_owner'] = scoring_df['team'].apply(lambda x: x.owner)
scoring_df['team_name_owner'] = scoring_df['team_name'] + ' (' + scoring_df['team_owner'] + ')'

## Scoring throughout the season
scoring_by_week_df = (scoring_df.groupby(['team_name','team_owner', 'week'])
                       .agg({'points':sum}))

### cumulative scoring throughout weeks 
cumulative_scoring_df = (scoring_df.drop(columns='player_id').groupby(['team_name', 'team_owner', 'week']).sum()
                          .groupby(level=0).cumsum().reset_index())

cumulative_scoring_df = cumulative_scoring_df[cumulative_scoring_df['week'] <= 12]

plt.style.use('fivethirtyeight')
ax = sns.lineplot(data = cumulative_scoring_df.query("week >= 8"), x='week', y='points', hue='team_owner')
ax.set_ylabel('points', fontsize = 10)
ax.set_xlabel('week', fontsize=10)
plt.yticks(fontsize=8)
plt.xticks(fontsize=8)
plt.legend(#loc=2,
           prop={'size': 9.5})
plt.show()


### Cumulative shown as points out of 1st place
first_place_points = cumulative_scoring_df.groupby('week').agg({'points': max}).reset_index().rename(columns={'points':'1st_place_pts'})
cumulative_scoring_df = cumulative_scoring_df.merge(first_place_points)
cumulative_scoring_df['points_out_of_1st'] = cumulative_scoring_df['points'] - cumulative_scoring_df['1st_place_pts']

plt.style.use('fivethirtyeight')
ax = sns.lineplot(data = cumulative_scoring_df, x='week',
                  y='points_out_of_1st', hue='team_owner',
                  style='team_owner', dashes=False)
ax.set_ylabel('points behind 1st', fontsize = 10)
ax.set_xlabel('week', fontsize=10)
plt.yticks(fontsize=8)
plt.xticks(fontsize=8)
plt.legend(#loc=2,
           prop={'size': 8})
plt.title("Team Points Over Time", fontsize=10)
plt.show()

## Merge in draft info
scoring_df = scoring_df.merge(draft_df[['player_id', 'overall_pick', 'round_num',
                                        'team_name']],
                              on = 'player_id', how = 'left', suffixes=('','_drafter'))
scoring_df['round_num'].fillna('FA', inplace = True)
scoring_df['round_num'] = scoring_df['round_num'].astype(str)
scoring_df['round_or_fa'] = scoring_df.apply(lambda x: 'FA' if x['team_name'] != x['team_name_drafter']
                                               else x['round_num'], axis = 1)
scoring_df['original_drafter_note'] = scoring_df.apply(lambda x: x['team_name_drafter'] if x['team_name'] != x['team_name_drafter']
                                               else '', axis = 1)

scoring_summary_df = (scoring_df.groupby(['team_name_owner', 'player_name', 'round_or_fa', 'original_drafter_note'])
                      .agg({'points':sum}).sort_values('points', ascending = False))

scoring_df['round_grouped'] = scoring_df['round_or_fa'].apply(lambda x: '5+' if x in [str(rd)+".0" for rd in range(5,17)]
                                                               else x[:-2] if x in [str(rd)+".0" for rd in range(1,5)]
                                                              else x)
grouped_df = (scoring_df.groupby(['team_name_owner', 'round_grouped'])
          .agg({'points':sum}).sort_values('points').unstack())

ax = (grouped_df['points']
      .plot(kind = 'barh', stacked = True,
            legend = ['round_grouped']))

#%% 

WEEKS = range(1,18)
teams = []
players = []
slot_positions = []
positions = []
scores = []
week_list = []
for week in WEEKS:
    for box in league.box_scores(week):
        for player in box.home_lineup:
            players.append(player)
            scores.append(player.points)
            positions.append(player.position)
            slot_positions.append(player.slot_position)
            teams.append(box.home_team)
            week_list.append(week)
        for player in box.away_lineup:
            players.append(player)
            scores.append(player.points)
            positions.append(player.position)
            slot_positions.append(player.slot_position)
            teams.append(box.away_team)
            week_list.append(week)
lineup_df = pd.DataFrame({'team': teams,
                          'player': players,
                          'position': positions,
                          'slot_position': slot_positions,
                          'points': scores,
                          'week': week_list})
lineup_df['player_id']   = lineup_df['player'].apply(lambda x: x.playerId)
lineup_df['player_name'] = lineup_df['player'].apply(lambda x: x.name)
lineup_df['team_name']   = lineup_df['team'].apply(lambda x: x.team_name)
lineup_df['team_owner']  = lineup_df['team'].apply(lambda x: x.owner)
lineup_df['team_name_owner'] = lineup_df['team_name'] + ' (' + lineup_df['team_owner'] + ')'


## Analyze "points left on the table" by not starting the right people
def get_optimal_subs(lineup_df):
    """
    Find out substitutions that should've been made.
    
    Note: still some edge cases to work out.  Logic could be improved and made simpler.
    
    Parameters
    ----------
    lineup_df :  DataFrame
        Complete list of points .
   
    
    Returns
    -------
    sub_df : DataFrame
        Table containing the substitutions that should have been made for an optimal lineup.

    """
    
    starter_df = lineup_df[~lineup_df['slot_position'].isin(['BE', 'IR'])]
    
    ## Very hacky manual fix b/c of Taysom Hill's QB position when slotted in TE
    starter_df['position'] = starter_df.apply(lambda x: 'TE' if ((x['player_name'] == 'Taysom Hill') and
                                                                (x['slot_position'] == 'TE'))
                                              else x['position'], axis = 1)
    
    starters_set = set(starter_df['player_id'])
    
    sub_df = pd.DataFrame()
    
    ## Get the top QB
    top_qb = lineup_df[lineup_df['position'] == 'QB'].sort_values('points', ascending = False).head(1).reset_index().drop(columns = 'index')
    if top_qb['player_id'][0] not in starters_set:
        current_starting_qb = starter_df[starter_df['position'] == 'QB'].reset_index()
        top_qb['sub_for_player_name'] = current_starting_qb['player_name'][0]
        top_qb['sub_for_player_id'] = current_starting_qb['player_id'][0]
        top_qb['sub_for_player_points'] = current_starting_qb['points'][0]
        top_qb['new_slot_position'] = 'QB'
        sub_df = sub_df.append(top_qb)
    
    ## Get the top 2 RBs:
    top_rbs = lineup_df[lineup_df['position'] == 'RB'].sort_values('points', ascending = False).head(2).reset_index().drop(columns = 'index')   
    
    ## Get the top 2 WRs:
    top_wrs = lineup_df[lineup_df['position'] == 'WR'].sort_values('points', ascending = False).head(2).reset_index().drop(columns = 'index')
    
    ## Get the top TE:
    top_te = lineup_df[lineup_df['position'] == 'TE'].sort_values('points', ascending = False).head(1).reset_index().drop(columns = 'index')
    
    ## Get the top FLEX (Top RB/WR/TE that is not in any of the lists above)
    top_wr_rb_te_ids = list(top_wrs['player_id']) + list(top_rbs['player_id']) + list(top_te['player_id'])
    top_flx = (lineup_df[(lineup_df['position'].isin(['RB', 'WR', 'TE'])) &
                         ~(lineup_df['player_id'].isin(top_wr_rb_te_ids))].sort_values('points', ascending = False)
                       .head(1).reset_index().drop(columns = 'index'))
    top_wr_rb_te_flx_ids = top_wr_rb_te_ids + list(top_flx['player_id'])
    top_wr_rb_te_flx_df = lineup_df[lineup_df['player_id'].isin(top_wr_rb_te_flx_ids)]
    
    ## Set the "sub for" columns now that we have the top RB/WR/TEs and old/new starters
    subbed_player_candidate_df = starter_df[~(starter_df['player_id'].isin(top_wr_rb_te_flx_ids)) &
                                             (starter_df['slot_position'].isin(['RB', 'WR', 'TE', 'RB/WR/TE']))].sort_values('points').reset_index().drop(columns = 'index')
    rb_removed_lineup_df = subbed_player_candidate_df[subbed_player_candidate_df['position'] == 'RB'].sort_values('points').reset_index().drop(columns = 'index')
    wr_removed_lineup_df = subbed_player_candidate_df[subbed_player_candidate_df['position'] == 'WR'].sort_values('points').reset_index().drop(columns = 'index')
    te_removed_lineup_df = subbed_player_candidate_df[subbed_player_candidate_df['position'] == 'TE'].sort_values('points').reset_index().drop(columns = 'index')
    #if len(top_wr_rb_te_flx_df[top_wr_rb_te_flx_df['position'] == 'TE']) == 1:
        ## If there's only 1 TE in the top RB/WR/TE/Flex DF, don't consider TEs benched as the substitute for the benched player
    #    subbed_player_candidate_df = subbed_player_candidate_df[subbed_player_candidate_df['position'] != 'TE']
    #if len(top_wr_rb_te_flx_df[top_wr_rb_te_flx_df['position'] == 'WR']) == 2:
        ## If there's only 2 WR in the top RB/WR/TE/Flex DF, don't consider WRs benched as the substitute for the benched player
    #    subbed_player_candidate_df = subbed_player_candidate_df[subbed_player_candidate_df['position'] != 'WR']
    #if len(top_wr_rb_te_flx_df[top_wr_rb_te_flx_df['position'] == 'RB']) == 2:
        ## If there's only 2 RB in the top RB/WR/TE/Flex DF, don't consider RBs benched as the substitute for the benched player
    #    subbed_player_candidate_df = subbed_player_candidate_df[subbed_player_candidate_df['position'] != 'RB']
    #flx_removed_lineup_df = subbed_player_candidate_df[subbed_player_candidate_df['slot_position'] == 'RB/WR/TE'].sort_values('points').reset_index().drop(columns = 'index')
    old_flex_position = starter_df[starter_df['slot_position'] == 'RB/WR/TE'].reset_index()['position'][0]
    old_flex_player = starter_df[starter_df['slot_position'] == 'RB/WR/TE'].reset_index()
    
    ## For RBs
    if len(sub_df) > 0:
        already_subbed_player_ids = list(sub_df['player_id'])
    else:
        already_subbed_player_ids = []
    ### Top scorer
    if top_rbs['player_id'][0] not in starters_set:
        top_rb1 = pd.DataFrame(top_rbs.iloc[0]).T
        if (len(subbed_player_candidate_df) == 1):
            sub_player = (subbed_player_candidate_df['player'][0])
        elif len(rb_removed_lineup_df) > 0:
            ## If at least 1 RB was removed from the lineup, 
            #  take the one with the least points as the one we're subbing out
            sub_player = rb_removed_lineup_df['player'][0]
        else:
            ## Otherwise we must've taken a flex out to make room for another RB, so we'll use that one
            sub_player = (subbed_player_candidate_df[
                (subbed_player_candidate_df['slot_position'] == old_flex_position) & 
                (~subbed_player_candidate_df['player_id'].isin(already_subbed_player_ids))].reset_index()['player'][0])
        top_rb1['sub_for_player_name'] = sub_player.name
        top_rb1['sub_for_player_id'] = sub_player.playerId
        top_rb1['sub_for_player_points'] = sub_player.points
        top_rb1['new_slot_position'] = 'RB'
        sub_df = sub_df.append(top_rb1)
    ### 2nd highest scorer at RB
    if len(sub_df) > 0:
        already_subbed_player_ids = list(sub_df['player_id'])
    else:
        already_subbed_player_ids = []
    if top_rbs['player_id'][1] not in starters_set:
        top_rb2 = pd.DataFrame(top_rbs.iloc[1]).T
        if (len(subbed_player_candidate_df) == 1):
            sub_player = (subbed_player_candidate_df['player'][0])
        elif (len(rb_removed_lineup_df) == 1) and (top_rbs['player_id'][0] in starters_set):
            ## If there was only 1 RB removed and we haven't already used RB1 as a sub from the bench
            sub_player = rb_removed_lineup_df['player'][0]
        elif len(rb_removed_lineup_df) >= 2:
            ## If there were 2 or more from the RB position removed, use the one with the 2nd highest points
            sub_player = rb_removed_lineup_df['player'][1]
        #elif old_flex_player['player_id'][0] not in top_wr_rb_te_flx_df['player_id']:
            ## Otherwise we must've taken a flex out to make room for another RB, so we'll use that one
        #    sub_player = (subbed_player_candidate_df[
        #        (subbed_player_candidate_df['slot_position'] == old_flex_position) & 
        #        (~subbed_player_candidate_df['player_id'].isin(already_subbed_player_ids))].reset_index()['player'][0])
        else:
            rb_not_yet_subbed = rb_removed_lineup_df[~rb_removed_lineup_df['player_id'].isin(sub_df)]
            wr_not_yet_subbed = wr_removed_lineup_df[~wr_removed_lineup_df['player_id'].isin(sub_df)]
            te_not_yet_subbed = te_removed_lineup_df[~te_removed_lineup_df['player_id'].isin(sub_df)]
            if len(rb_not_yet_subbed) > 0: 
                sub_player = (rb_not_yet_subbed['player'][0])
            elif len(wr_not_yet_subbed) > 0: 
                sub_player = (wr_not_yet_subbed['player'][0])
            elif len(te_not_yet_subbed) > 0: 
                sub_player = (te_not_yet_subbed['player'][0])

        top_rb2['sub_for_player_name'] = sub_player.name
        top_rb2['sub_for_player_id'] = sub_player.playerId
        top_rb2['sub_for_player_points'] = sub_player.points
        top_rb2['new_slot_position'] = 'RB'
        sub_df = sub_df.append(top_rb2)

    ## For WRs
    ### Top scorer
    if len(sub_df) > 0:
        already_subbed_player_ids = list(sub_df['player_id'])
    else:
        already_subbed_player_ids = []
    if top_wrs['player_id'][0] not in starters_set:
        top_wr1 = pd.DataFrame(top_wrs.iloc[0]).T
        #print(subbed_player_candidate_df[['player_name', 'slot_position', 'position', 'points']])
        #print(len(subbed_player_candidate_df))
        if (len(subbed_player_candidate_df) == 1):
            sub_player = (subbed_player_candidate_df['player'][0])
        elif len(wr_removed_lineup_df) > 0:
            ## If at least 1 RB was removed from the lineup, 
            #  take the one with the least points as the one we're subbing out
            sub_player = wr_removed_lineup_df['player'][0]
        else:
            ## Otherwise we must've taken out a player from the flex position to make room for another WR, so we'll use that one
            sub_player = (subbed_player_candidate_df[
                (subbed_player_candidate_df['position'] == old_flex_position) & 
                (~subbed_player_candidate_df['player_id'].isin(already_subbed_player_ids))].reset_index()['player'][0])
        top_wr1['sub_for_player_name'] = sub_player.name
        top_wr1['sub_for_player_id'] = sub_player.playerId
        top_wr1['sub_for_player_points'] = sub_player.points
        top_wr1['new_slot_position'] = 'WR'
        sub_df = sub_df.append(top_wr1)
    ### 2nd highest scorer at WR
    if len(sub_df) > 0:
        already_subbed_player_ids = list(sub_df['player_id'])
    else:
        already_subbed_player_ids = []
    if top_wrs['player_id'][1] not in starters_set:
        top_wr2 = pd.DataFrame(top_wrs.iloc[1]).T
        if (len(subbed_player_candidate_df) == 1):
            sub_player = (subbed_player_candidate_df['player'][0])
        elif (len(wr_removed_lineup_df) == 1) and (top_wrs['player_id'][0] in starters_set):
            ## If there was only 1 WR removed and we haven't already used WR1 as a sub from the bench
            sub_player = wr_removed_lineup_df['player'][0]
        elif len(wr_removed_lineup_df) > 1:
            ## If there were 2 or more from the WR position removed, use the one with the 2nd highest points
            sub_player = wr_removed_lineup_df['player'][1]
        else:
            ## Otherwise we must've taken out a player from the flex position to make room for another WR, so we'll use that one
            sub_player = (subbed_player_candidate_df[
                (subbed_player_candidate_df['position'] == old_flex_position) & 
                (~subbed_player_candidate_df['player_id'].isin(already_subbed_player_ids))].reset_index()['player'][0])
        top_wr2['sub_for_player_name'] = sub_player.name
        top_wr2['sub_for_player_id'] = sub_player.playerId
        top_wr2['sub_for_player_points'] = sub_player.points
        top_wr2['new_slot_position'] = 'WR'
        sub_df = sub_df.append(top_wr2)
    
    ## For TE
    if len(sub_df) > 0:
        already_subbed_player_ids = list(sub_df['player_id'])
    else:
        already_subbed_player_ids = []
    if top_te['player_id'][0] not in starters_set:
        if (len(subbed_player_candidate_df) == 1):
            sub_player = (subbed_player_candidate_df['player'][0])
        elif len(te_removed_lineup_df) == 1:
            sub_player = te_removed_lineup_df['player'][0]
        elif len(top_wr_rb_te_flx_df[top_wr_rb_te_flx_df['position'] == 'TE']) == 2:
            ## Moved the starting TE to the flex and now have 2 TEs
            rb_not_yet_subbed = rb_removed_lineup_df[~rb_removed_lineup_df['player_id'].isin(sub_df)]
            wr_not_yet_subbed = wr_removed_lineup_df[~wr_removed_lineup_df['player_id'].isin(sub_df)]
            if len(rb_not_yet_subbed) > 0: 
                sub_player = (rb_not_yet_subbed['player'][0])
            elif len(wr_not_yet_subbed) > 0: 
                sub_player = (wr_not_yet_subbed['player'][0])

        else:
            # Otherwise we must've taken a flex out to make room for another TE, so we'll use that one
            sub_player = (subbed_player_candidate_df[
                (subbed_player_candidate_df['slot_position'] == old_flex_position) & 
                (~subbed_player_candidate_df['player_id'].isin(already_subbed_player_ids))].reset_index()['player'][0])
            
        top_te['sub_for_player_name'] = sub_player.name
        top_te['sub_for_player_id'] = sub_player.playerId
        top_te['sub_for_player_points'] = sub_player.points
        top_te['new_slot_position'] = 'TE'
        sub_df = sub_df.append(top_te)
    
    ## For Flex (RB/WR/TE)
    if top_flx['player_id'][0] not in starters_set:
        ## The player we took out for the new flex player is tricky... here's the logic in plain English
        """
        Scenarios:
         1. If we had 3 RBs in before and now only 2, then we choose the RB removed with the most points
             (this scenario may break if we subbed 2 RBs out and added 1 off the bench,
              in this case we should take the one subbed out with the most points)
         2. Same for WRs
         3. If we had 2 TEs before and now only have 1, then we choose the TE removed
         4. If we have equal number before and after AND only 1 player was removed, 
             we must have replaced the flex with the same position.
         5. OR we substituted 2 or 3 of the same position for each other, in which case we take 
             the one with the most points scored as our sub (because we took the lowest points
                                                             for RB1, 2nd for RB2, etc.)
        We can simplify the last 2 scenarios by just applying the most points case
        """
        
        if (len(subbed_player_candidate_df) == 1):
            sub_player = (subbed_player_candidate_df['player'][0])
        elif ((len(starter_df[starter_df['position'] == 'RB']) == 3) and
           (len(top_wr_rb_te_flx_df[top_wr_rb_te_flx_df['position'] == 'RB']) == 2)):
            sub_player = (rb_removed_lineup_df['player'][len(rb_removed_lineup_df)-1])
        elif ((len(starter_df[starter_df['position'] == 'WR']) == 3) and
           (len(top_wr_rb_te_flx_df[top_wr_rb_te_flx_df['position'] == 'WR']) == 2)):
            sub_player = (wr_removed_lineup_df['player'][len(wr_removed_lineup_df)-1])
        elif ((len(starter_df[starter_df['position'] == 'TE']) == 2) and
           (len(top_wr_rb_te_flx_df[top_wr_rb_te_flx_df['position'] == 'TE']) == 1)):
            sub_player = (te_removed_lineup_df['player'][len(te_removed_lineup_df)-1])
        
        ## Can we replace all of the above with just this??
        elif old_flex_position == 'WR':
            sub_player = (wr_removed_lineup_df['player'][len(wr_removed_lineup_df)-1])
        elif old_flex_position == 'RB':
            sub_player = (rb_removed_lineup_df['player'][len(rb_removed_lineup_df)-1])
        elif old_flex_position == 'TE':
            sub_player = (te_removed_lineup_df['player'][len(te_removed_lineup_df)-1])
        
        top_flx['sub_for_player_name'] = sub_player.name
        top_flx['sub_for_player_id'] = sub_player.playerId
        top_flx['sub_for_player_points'] = sub_player.points
        top_flx['new_slot_position'] = 'RB/WR/TE'
        sub_df = sub_df.append(top_flx)
    
    
    ## Get the top D/ST:
    top_d = lineup_df[lineup_df['position'] == 'D/ST'].sort_values('points', ascending = False).head(1).reset_index().drop(columns = 'index')
    if len(top_d) > 0:
        if top_d['player_id'][0] not in starters_set:
            current_starting_d = starter_df[starter_df['position'] == 'D/ST'].reset_index()
            if len(current_starting_d) > 0:
                top_d['sub_for_player_name'] = current_starting_d['player_name'][0]
                top_d['sub_for_player_id'] = current_starting_d['player_id'][0]
                top_d['sub_for_player_points'] = current_starting_d['points'][0]
            else: 
                top_d['sub_for_player_name'] = 'No Defense'
                top_d['sub_for_player_id'] = None
                top_d['sub_for_player_points'] = 0          
            sub_df = sub_df.append(top_d)
    
    ## Get the top K:
    top_k = lineup_df[lineup_df['position'] == 'K'].sort_values('points', ascending = False).head(1).reset_index().drop(columns = 'index')
    if top_k['player_id'][0] not in starters_set:
        current_starting_k = starter_df[starter_df['position'] == 'K'].reset_index()
        top_k['sub_for_player_name'] = current_starting_k['player_name'][0]
        top_k['sub_for_player_id'] = current_starting_k['player_id'][0]
        top_k['sub_for_player_points'] = current_starting_k['points'][0]
        sub_df = sub_df.append(top_k)
    
    return sub_df


### Gather the subs that should've been made
unique_week_team_lineup = lineup_df.groupby(['team_name', 'week']).size().reset_index().drop(columns = 0)
sub_dfs = []
for i, row in unique_week_team_lineup.iterrows():
    sub_lineup_df = lineup_df[(lineup_df['week'] == row['week']) & 
                              (lineup_df['team_name'] == row['team_name'])]
    sub_df = get_optimal_subs(sub_lineup_df)
    sub_dfs.append(sub_df)
full_sub_df = pd.concat(sub_dfs).reset_index()
full_sub_df['potential_extra_points'] = full_sub_df['points'] - full_sub_df['sub_for_player_points']

### Visualize missed opportunities by team
subs_pts_by_team = full_sub_df.groupby('team_owner').agg({'potential_extra_points': sum,
                                       'index': len}).rename(columns = {'index': 'n_subs'}).reset_index()
subs_pts_by_team['bar_label'] = subs_pts_by_team['team_owner'] + ' (' + subs_pts_by_team['n_subs'].astype(str)  + ')'

ax = (subs_pts_by_team.sort_values(by='potential_extra_points').plot(x = 'bar_label', y = 'potential_extra_points',
                                                     title = 'Extra Points Left on Bench\n(Number of substitutions in parens.)', 
                                                     kind = 'barh', legend = None))
ax.set_xlabel("")
ax.set_ylabel("")


### Create a grouped bar chart...  (or attempt)
potential_points_by_team_and_player = (full_sub_df
                                       .groupby(['team_owner', 'player_name'])
                                       .agg({'potential_extra_points': sum}))

top_3_subs_by_owner = (potential_points_by_team_and_player['potential_extra_points']
                       .groupby('team_owner', group_keys=False).nlargest(2).reset_index())

top_3_subs_by_owner['owner_first_name'] = top_3_subs_by_owner['team_owner'].apply(lambda x: x.split(' ')[0])
top_3_subs_by_owner['bar_label'] = top_3_subs_by_owner['owner_first_name'] + " would've started " + top_3_subs_by_owner['player_name']

ax = top_3_subs_by_owner.sort_values(by = 'potential_extra_points').plot(y = 'potential_extra_points', x = 'bar_label',
                                                                         legend = None, kind = 'barh', title = 'If only...')
ax.set_xlabel("Potential extra points gained")
ax.set_ylabel("")


### Top owner/player subs (and how many times)
potential_points_by_team_and_player = (full_sub_df
                                       .groupby(['team_owner', 'player_name'])
                                       .agg({'potential_extra_points': sum,
                                             'index': len})
                                       .sort_values('potential_extra_points', ascending = False)
                                       .head(10).rename(columns = {'index': 'n_subs'}).reset_index())

potential_points_by_team_and_player['owner_first_name'] = potential_points_by_team_and_player['team_owner'].apply(lambda x: x.split(' ')[0])
potential_points_by_team_and_player['bar_label'] = (potential_points_by_team_and_player['owner_first_name'] + 
                                                    " would've started " + potential_points_by_team_and_player['player_name'] + 
                                                    ' (' + potential_points_by_team_and_player['n_subs'].astype(str) + ')')

ax = (potential_points_by_team_and_player.sort_values(by = 'potential_extra_points')
      .plot(y = 'potential_extra_points', x = 'bar_label', legend = None, 
            kind = 'barh', title = 'If only...'))
ax.set_xlabel("Potential extra points gained")
ax.set_ylabel("")



### Create a grouped bar chart... 
potential_points_by_team_and_player = (full_sub_df
                                       .groupby(['team_owner', 'sub_for_player_name'])
                                       .agg({'potential_extra_points': sum}))

top_3_subs_by_owner = (potential_points_by_team_and_player['potential_extra_points']
                       .groupby('team_owner', group_keys=False).nlargest(2).reset_index())

top_3_subs_by_owner['owner_first_name'] = top_3_subs_by_owner['team_owner'].apply(lambda x: x.split(' ')[0])
top_3_subs_by_owner['bar_label'] = top_3_subs_by_owner['owner_first_name'] + " would've benched " + top_3_subs_by_owner['sub_for_player_name']

ax = top_3_subs_by_owner.sort_values(by = 'potential_extra_points').plot(y = 'potential_extra_points', x = 'bar_label', legend = None, kind = 'barh', title = 'If only...')
ax.set_xlabel("Potential extra points gained")
ax.set_ylabel("")


### Top owner/player subs (and how many times)
potential_points_by_team_and_b_player = (full_sub_df
                                       .groupby(['team_owner', 'sub_for_player_name'])
                                       .agg({'potential_extra_points': sum,
                                             'index': len})
                                       .sort_values('potential_extra_points', ascending = False)
                                       .head(10).rename(columns = {'index': 'n_subs'}).reset_index())

potential_points_by_team_and_b_player['owner_first_name'] = potential_points_by_team_and_b_player['team_owner'].apply(lambda x: x.split(' ')[0])
potential_points_by_team_and_b_player['bar_label'] = (potential_points_by_team_and_b_player['owner_first_name'] + 
                                                    " would've benched " + potential_points_by_team_and_b_player['sub_for_player_name'] + 
                                                    ' (' + potential_points_by_team_and_b_player['n_subs'].astype(str) + ')')

ax = (potential_points_by_team_and_b_player.sort_values(by = 'potential_extra_points')
      .plot(y = 'potential_extra_points', x = 'bar_label', legend = None, 
            kind = 'barh', title = 'If only...'))
ax.set_xlabel("Potential extra points gained")
ax.set_ylabel("")
