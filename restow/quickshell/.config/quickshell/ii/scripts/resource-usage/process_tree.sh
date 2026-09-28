#!/bin/sh
# process_tree.sh — Fast process tree + GPU engine utilization scanner
# Aggregates multi-process application hierarchies under parent roots.
# Calculates delta CPU ticks and DRM engine-render utilization percentage.
# Outputs JSON for Quickshell: {"top_cpu":[...],"top_gpu":[...]}

STATE="${XDG_RUNTIME_DIR:-/tmp}/qs_proc_state.tsv"

{
    # 1. Timestamp (ns) and total system CPU ticks from /proc/stat
    printf '=H\t%s\t' "$(date +%s%N)"
    awk '/^cpu /{s=0;for(i=2;i<=9;i++)s+=$i;print s}' /proc/stat

    # 2. Previous run state cache
    [ -f "$STATE" ] && sed 's/^/=S\t/' "$STATE"

    # 3. Process stat records (skip missing/exited files cleanly with BEGINFILE)
    awk '
    BEGINFILE { if (ERRNO) nextfile }
    {
        l=$0; rp=0
        for(i=length(l);i>=1;i--) if(substr(l,i,1)==")"){rp=i;break}
        if(!rp) next
        lp=index(l,"(")
        pid=substr(l,1,lp-2)+0
        comm=substr(l,lp+1,rp-lp-1)
        rest=substr(l,rp+2); n=split(rest,f," ")
        if(n<20) next
        ppid=f[2]+0
        if(pid<=2 || ppid==2) next
        printf "=P\t%d\t%d\t%s\t%d\t%s\n",pid,ppid,comm,f[12]+f[13],f[20]
    }' /proc/[0-9]*/stat 2>/dev/null

    # 4. DRM engine-render nanoseconds (deduplicated per client)
    grep -H 'drm-client-id:\|drm-engine-render:' \
         /proc/[0-9]*/fdinfo/[0-9]* 2>/dev/null |
    awk -F: '
    {
        split($1,pp,"/"); pid=pp[3]; fd=pp[5]; k=pid"/"fd
        if($2=="drm-client-id"){v=$3;gsub(/[^0-9]/,"",v);cid[k]=v+0}
        if($2=="drm-engine-render"){v=$3;gsub(/[^0-9]/,"",v);eng[k]=v+0}
    }
    END{
        for(k in cid){
            split(k,kp,"/"); pid=kp[1]; c=cid[k]; e=eng[k]+0
            dk=pid":"c
            if(!(dk in seen)){seen[dk]=1; if(e>mx[pid]+0)mx[pid]=e}
        }
        for(pid in mx) if(mx[pid]>0) printf "=D\t%s\t%d\n",pid,mx[pid]
    }' || true

} | awk -F'\t' -v state_out="$STATE.tmp" '
BEGIN { np=0 }

$1=="=H" { now_ns=$2+0; sys_ticks=$3+0 }

$1=="=S" {
    if($2=="H"){ p_time=$3+0; p_sys=$4+0 }
    else { pt[$2+0]=$3+0; pe[$2+0]=$4+0 }
}

$1=="=P" {
    pid=$2+0
    ppid[pid]=$3+0; comm[pid]=$4; ticks[pid]=$5+0; st[pid]=$6+0
    cpu[pid]=0; eng[pid]=0; gpu[pid]=0
    plist[++np]=pid; alive[pid]=1
}

$1=="=D" { drm[$2+0]=$3+0 }

function jesc(s) { gsub(/\\/,"\\\\",s); gsub(/"/,"\\\"",s); return s }

END {
    for(pid in drm) if(pid in alive) eng[pid]=drm[pid]

    wdt=0; if(p_time>0) wdt=(now_ns-p_time)/1000000000
    dsys=sys_ticks-p_sys

    if(wdt>0.05 && wdt<10 && dsys>0){
        for(i=1;i<=np;i++){
            pid=plist[i]
            if(pid in pt){
                d=ticks[pid]-pt[pid]; if(d<0)d=0
                cpu[pid]=d/dsys*100
            }
            if(eng[pid]>0 && (pid in pe) && pe[pid]>0){
                de=eng[pid]-pe[pid]; if(de<0)de=0
                gpu[pid]=de/(wdt*1000000000)*100
                if(gpu[pid]>100) gpu[pid]=100
            }
        }
    } else {
        for(i=1;i<=np;i++){
            pid=plist[i]
            el=sys_ticks-st[pid]; if(el>0) cpu[pid]=ticks[pid]/el*100
        }
    }

    # Save state cache
    printf "H\t%s\t%d\n",now_ns,sys_ticks > state_out
    for(i=1;i<=np;i++){
        pid=plist[i]
        printf "%d\t%d\t%d\n",pid,ticks[pid],eng[pid] > state_out
    }
    close(state_out)

    # Boundaries for process hierarchy climbing (must pass " " as 3rd arg since FS is \t)
    split("systemd init login pipewire seatd (sd-pam) start-hyprland systemd-logind kthreadd",_sr, " ")
    for(x in _sr) sysroot[_sr[x]]=1

    split("kitty alacritty foot wezterm gnome-terminal konsole",_te, " ")
    for(x in _te) termemu[_te[x]]=1
    termemu["tmux: server"]=1

    split("sh bash zsh fish dash csh tcsh nu",_sh, " ")
    for(x in _sh) shells[_sh[x]]=1

    split("systemd init login seatd (sd-pam) systemd-logind kthreadd",_sk, " ")
    for(x in _sk) skip_roots[_sk[x]]=1

    for(i=1;i<=np;i++){
        pid=plist[i]; curr=pid
        for(it=0;it<50;it++){
            if(!(curr in ppid)||ppid[curr]<=1) break
            par=ppid[curr]
            if(!(par in comm)) break
            pc=comm[par]; sub(/^-/,"",pc)
            cc=comm[curr]; sub(/^-/,"",cc)
            if(pc in sysroot||index(pc,"systemd")>0) break
            if(pc in termemu) break
            if(pc in shells && cc!=pc) break
            if(cc==pc||(pc in shells)){ curr=par; continue }
            curr=par
        }
        root[pid]=curr
    }

    na=0
    for(i=1;i<=np;i++){
        pid=plist[i]; r=root[pid]
        rc=comm[r]; sub(/^-/,"",rc)
        # Skip pure daemon/system roots like login or systemd-logind
        if(rc in skip_roots) continue
        if(!(r in aidx)){
            aidx[r]=++na; aroot[na]=r
            acpu[na]=0; agpu[na]=0; acnt[na]=0; anch[na]=0
        }
        ix=aidx[r]; acpu[ix]+=cpu[pid]
        agpu[ix]+=gpu[pid]
        acnt[ix]++
        if(cpu[pid]>=0.5||gpu[pid]>=0.5){
            nc=++anch[ix]
            if(nc<=10){ chpid[ix,nc]=pid; chcpu[ix,nc]=cpu[pid]; chgpu[ix,nc]=gpu[pid] }
        }
    }

    # Normalize human-friendly application names
    for(i=1;i<=na;i++){
        if(agpu[i]>100) agpu[i]=100
        nm=comm[aroot[i]]; sub(/^-/,"",nm); ln=tolower(nm)
        if(index(ln,"chrome")>0) nm="Google Chrome"
        else if(index(ln,"discord")>0) nm="Discord"
        else if(index(ln,"librewolf")>0) nm="LibreWolf"
        else if(index(ln,"kitty")>0) nm="Kitty"
        else if(index(ln,"hyprland")>0) nm="Hyprland"
        else if(ln=="qs"||index(ln,"quickshell")>0) nm="Quickshell"
        else if(index(ln,"code")>0) nm="VS Code"
        aname[i]=nm
    }

    # Sort top_cpu (selection sort, top 7)
    for(i=1;i<=na;i++){ cord[i]=i; cval[i]=acpu[i] }
    for(i=1;i<=na&&i<=7;i++){
        mx=i; for(j=i+1;j<=na;j++) if(cval[j]>cval[mx]) mx=j
        if(mx!=i){ t=cord[i];cord[i]=cord[mx];cord[mx]=t; t=cval[i];cval[i]=cval[mx];cval[mx]=t }
    }
    ncpu=na; if(ncpu>7) ncpu=7

    # Sort top_gpu (selection sort, top 7, gpu>=0.1 only)
    ngc=0
    for(i=1;i<=na;i++) if(agpu[i]>=0.1){ gc[++ngc]=i; gval[ngc]=agpu[i] }
    for(i=1;i<=ngc&&i<=7;i++){
        mx=i; for(j=i+1;j<=ngc;j++) if(gval[j]>gval[mx]) mx=j
        if(mx!=i){ t=gc[i];gc[i]=gc[mx];gc[mx]=t; t=gval[i];gval[i]=gval[mx];gval[mx]=t }
    }
    ngpu=ngc; if(ngpu>7) ngpu=7

    printf "{\"top_cpu\":["
    for(i=1;i<=ncpu;i++){
        ix=cord[i]
        if(i>1) printf ","
        printf "{\"pid\":%d,\"name\":\"%s\",\"total_cpu\":%.1f,\"total_gpu_pct\":%.1f,\"total_gpu_mb\":%.1f,\"count\":%d,\"children\":[",
            aroot[ix],jesc(aname[ix]),acpu[ix],agpu[ix],agpu[ix],acnt[ix]
        nch=anch[ix]; if(nch>10) nch=10
        for(ci=1;ci<=nch;ci++) co[ci]=ci
        for(ci=1;ci<=nch&&ci<=3;ci++){
            mx=ci; for(cj=ci+1;cj<=nch;cj++) if(chcpu[ix,co[cj]]>chcpu[ix,co[mx]]) mx=cj
            if(mx!=ci){t=co[ci];co[ci]=co[mx];co[mx]=t}
        }
        nco=nch; if(nco>3) nco=3
        for(ci=1;ci<=nco;ci++){
            cpid=chpid[ix,co[ci]]
            cnm=comm[cpid]; sub(/^-/,"",cnm)
            if(ci>1) printf ","
            printf "{\"pid\":%d,\"name\":\"%s\",\"cpu\":%.1f,\"gpu_pct\":%.1f,\"gpu_mb\":%.1f}",
                cpid,jesc(cnm),chcpu[ix,co[ci]],chgpu[ix,co[ci]],chgpu[ix,co[ci]]
        }
        printf "]}"
    }
    printf "],\"top_gpu\":["
    for(i=1;i<=ngpu;i++){
        ix=gc[i]
        if(i>1) printf ","
        printf "{\"pid\":%d,\"name\":\"%s\",\"total_cpu\":%.1f,\"total_gpu_pct\":%.1f,\"total_gpu_mb\":%.1f,\"count\":%d,\"children\":[",
            aroot[ix],jesc(aname[ix]),acpu[ix],agpu[ix],agpu[ix],acnt[ix]
        nch=anch[ix]; if(nch>10) nch=10
        for(ci=1;ci<=nch;ci++) co2[ci]=ci
        for(ci=1;ci<=nch&&ci<=3;ci++){
            mx=ci; for(cj=ci+1;cj<=nch;cj++) if(chgpu[ix,co2[cj]]>chgpu[ix,co2[mx]]) mx=cj
            if(mx!=ci){t=co2[ci];co2[ci]=co2[mx];co2[mx]=t}
        }
        nco=nch; if(nco>3) nco=3
        for(ci=1;ci<=nco;ci++){
            cpid=chpid[ix,co2[ci]]
            cnm=comm[cpid]; sub(/^-/,"",cnm)
            if(ci>1) printf ","
            printf "{\"pid\":%d,\"name\":\"%s\",\"cpu\":%.1f,\"gpu_pct\":%.1f,\"gpu_mb\":%.1f}",
                cpid,jesc(cnm),chcpu[ix,co2[ci]],chgpu[ix,co2[ci]],chgpu[ix,co2[ci]]
        }
        printf "]}"
    }
    printf "]}\n"
}
'
mv -f "$STATE.tmp" "$STATE" 2>/dev/null || true
