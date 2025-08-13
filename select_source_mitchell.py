import numpy as np
from obspy.geodetics.base import gps2dist_azimuth
n_target = 112
fn_candidate = 'src_rec_noise/sources_candidate.dat'
fn_exist = 'src_rec_noise/sources_selected.dat'
#fn_exist = ''
fn_selected = 'src_rec_noise/sources_batch.dat'
fn_unselected = 'src_rec_noise/sources_unselected.dat'
candidate = {}
selected = {}
try:
    with open(fn_exist,'r') as f_exist:
        lines = f_exist.readlines()
except:
    lines = []
n_exist = len(lines)
print(f"{n_exist} stations already selected")
for line in lines:
    line_segs = line.strip().split(' ')
    line_segs = [_ for _ in line_segs if _ != '']
    sta = line_segs[0]
    nt = line_segs[1]
    lat = float(line_segs[2])
    lon = float(line_segs[3])
    src_code = sta
    selected[src_code] = (nt, sta, lat, lon)

print(selected)

with open(fn_candidate,'r') as f_candidate:
    lines = f_candidate.readlines()
n_total = len(lines)
for line in lines:
    line_segs = line.strip().split(' ')
    line_segs = [_ for _ in line_segs if _ != '']
    sta = line_segs[0]
    nt = line_segs[1]
    lat = float(line_segs[2])
    lon = float(line_segs[3])
    src_code = sta
    if src_code not in selected:
        candidate[src_code] = (nt, sta, lat, lon)
n_candidate = len(candidate)
print(f"{n_candidate} candidates")


if (n_total < n_target - n_exist):
    print("not enough candidates")

n_selected = n_exist
while (n_selected < n_target):
    lst_candidate = list(candidate.keys())
    lst_selected = list(selected.keys())
    if (n_selected == 0):
        i_selected = np.random.randint(n_candidate)
    else:
        min_dist_lst = []
        for src_candidate in lst_candidate:
            tuple_temp = candidate[src_candidate]
            lat1 = tuple_temp[2]
            lon1 = tuple_temp[3]
            min_dist = 1.0e20
            for src_selected in lst_selected:
                tuple_temp = selected[src_selected]
                lat2 = tuple_temp[2]
                lon2 = tuple_temp[3]
                # compute distance between candidate and selected
                this_dist,_,_ = gps2dist_azimuth(lat1,lon1,lat2,lon2)
                if (this_dist < min_dist):
                    min_dist = this_dist # keep the min distance
            min_dist_lst.append(min_dist)
        i_selected = np.argmax(min_dist_lst)
    this_src_code = lst_candidate[i_selected]
    selected[this_src_code] = candidate[this_src_code]
    n_selected = n_selected + 1
    print(f"{n_selected}th station: {this_src_code}")
    candidate.pop(this_src_code)
    n_candidate = n_candidate - 1

f_selected = open(fn_selected, 'w')
for src_selected in selected:
    tuple_temp = selected[src_selected]
    sta = tuple_temp[1]
    nt = tuple_temp[0]
    lat = tuple_temp[2]
    lon = tuple_temp[3]
    f_selected.write("%-11s%2s%14.4f%12.4f      0.0     0.0\n" % (sta, nt, lat, lon))
f_selected.close()

f_unselected = open(fn_unselected, 'w')
for src_candidate in candidate:
    tuple_temp = candidate[src_candidate]
    sta = tuple_temp[1]
    nt = tuple_temp[0]
    lat = tuple_temp[2]
    lon = tuple_temp[3]
    f_unselected.write("%-11s%2s%14.4f%12.4f      0.0     0.0\n" % (sta, nt, lat, lon))
f_unselected.close()
