#!/bin/bash
# Downloads the offline first-aid video set (official sources only), 720p H.264 MP4 so it plays
# everywhere (QuickTime/Safari, Windows, phones). About 900 MB for all 48.
#   bash common/get-videos.sh [output-folder]
# Needs yt-dlp and ffmpeg (official builds: github.com/yt-dlp/yt-dlp, ffmpeg.org).
# Set YTDLP / FFMPEG_DIR if they're not on the PATH. On Windows, give a path like D:/Emergency/Videos:
# yt-dlp.exe misreads /d/... paths.
Y="${YTDLP:-yt-dlp}"
OUT="${1:-./Emergency Videos}"
FMT='bv*[height<=720][vcodec^=avc1]+ba[acodec^=mp4a]/b[height<=720][ext=mp4]/b[height<=720]'
FF=(); [ -n "${FFMPEG_DIR:-}" ] && FF=(--ffmpeg-location "$FFMPEG_DIR")

get() {  # folder, video id
    mkdir -p "$OUT/$1"
    "$Y" -f "$FMT" --merge-output-format mp4 --no-playlist --no-overwrites \
        "${FF[@]}" \
        -o "$OUT/$1/%(title).80s [%(channel)s].%(ext)s" "https://www.youtube.com/watch?v=$2"
}

get "01 CPR and AED" hblmFtbyYKQ      # AHA: Learn Hands-Only CPR in 90 seconds
get "01 CPR and AED" 6eRwgM2Pa4o      # American Red Cross: Hands-Only CPR
get "01 CPR and AED" rCN5DU897r4      # Canadian Red Cross: CPR and AED
get "01 CPR and AED" mJKQMbffcEs      # Canadian Red Cross: infant CPR
get "01 CPR and AED" in8j2Q2z3HE      # American Red Cross: AED on an adult
get "01 CPR and AED" yp5gjJa2FxA      # American Red Cross: AED on children and infants
get "02 Choking" 8R3RWC-xx1I          # American Red Cross: adult choking
get "02 Choking" ShaNuST_58A          # American Red Cross: infant choking (responsive)
get "02 Choking" NF9oSpXt19c          # American Red Cross: infant choking (unresponsive)
get "02 Choking" ePodw7L_mFM          # British Red Cross: choking baby
get "03 Severe bleeding" NxO5LvgqZe0  # St John Ambulance: severe bleeding
get "03 Severe bleeding" 6jmnMC76oF4  # American Red Cross: severe bleeding
get "03 Severe bleeding" u3nrDb5XjSI  # Seattle OEM: Stop the Bleed tourniquet
get "03 Severe bleeding" mhBe7Q6mH3U  # UC San Diego Health: How to Stop the Bleed
get "04 Burns" IOtnGl_9-qw            # British Red Cross: burns
get "05 Heart attack and stroke" Es-Cr9uRXgQ  # AHA: heart attack warning signs
get "05 Heart attack and stroke" ZDhzCIi0_wA  # Heart & Stroke: stroke FAST
get "05 Heart attack and stroke" kr4syeWvaI8  # Stanford Health Care: BE FAST
get "06 Unconscious person" GmqXqwSV3bo       # St John Ambulance: recovery position
get "06 Unconscious person" 5fK2oCiz8VU       # British Red Cross: unresponsive but breathing
get "07 Outage safety" bsJzrGTB_aA    # FEMA: generator safety
get "07 Outage safety" 1_iIguAxDl0    # Texas Dept of Insurance: generator safety
get "07 Outage safety" wILOPUiOQaA    # FEMA/CDC: water safety after a disaster
get "03 Severe bleeding" k98ilfQmUWw  # American Red Cross: using a tourniquet
get "06 Unconscious person" ddHKwkMwNyI       # St John Ambulance: fainting
get "07 Outage safety" vMNqXakhb00    # FEMA/USDA: food safety after a disaster
get "08 Allergic reaction" O-8pPTVql5k        # American Red Cross: anaphylaxis
get "08 Allergic reaction" 8EyYTW-1EP0        # British Red Cross: severe allergic reactions
get "08 Allergic reaction" L501Sb7y5Kk        # Cleveland Clinic: how to use an EpiPen
get "09 Cold injuries" DewzkBh2onc    # British Red Cross: hypothermia
get "09 Cold injuries" j9E4gAnNeSY    # Australia Wide First Aid: frostbite
get "10 Seizures" 3Ihn1q3rfuQ         # Canadian Red Cross: seizures
get "10 Seizures" 1SMFUwyEafw         # British Red Cross: seizures
get "10 Seizures" sgucBed_kig         # British Red Cross: baby with a fever seizure
get "11 Asthma and diabetes" hdVKpUR513M      # St John Ambulance: asthma attack
get "11 Asthma and diabetes" sWYxsU53ZCo      # British Red Cross: diabetic emergencies
get "12 Bones, sprains, head injury" CP-vb0xxzFM  # British Red Cross: broken bone
get "12 Bones, sprains, head injury" 3CEiFmVzzyc  # British Red Cross: strains and sprains
get "12 Bones, sprains, head injury" OqDdLUi7kkA  # British Red Cross: head injury
get "12 Bones, sprains, head injury" K88n8m4eJwM  # American Red Cross: concussion
get "13 Poisoning" PgGUSAM6XJw        # British Red Cross: poisoning
get "13 Poisoning" W-yblSLugzo        # Canadian Red Cross: poisoning
get "14 Minor cuts and nosebleeds" nG_F4bqUWKI    # Canadian Red Cross: minor bleeding
get "14 Minor cuts and nosebleeds" PmmhxW0vVXA    # St John Ambulance: nosebleeds
get "15 Fire safety" DQeAwADGi0M      # San Jose Fire Dept: using a fire extinguisher
get "15 Fire safety" tNYcJaeaRQg      # American Red Cross: home fire escape plan
get "16 Stress and coping" yJaUeRVlvas        # New Zealand Red Cross: psychological first aid
get "17 Car" uyvGISHCDgQ              # Les Schwab: jump-starting a car
echo "ALL DONE"
