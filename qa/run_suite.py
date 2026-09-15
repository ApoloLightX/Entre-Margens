"""Run each Godot test with isolated user data; save complete logs and a summary."""
import argparse, json, os, pathlib, subprocess
parser=argparse.ArgumentParser();parser.add_argument('--godot',default='godot');args=parser.parse_args()
root=pathlib.Path(__file__).resolve().parents[1]
out=root/'tests-results'/'polish-210';out.mkdir(parents=True,exist_ok=True)
results=[]
for p in sorted((root/'godot/tests').glob('*.gd')):
    env=os.environ.copy();env['XDG_DATA_HOME']=str(out/'user-data'/p.stem)
    run=subprocess.run([args.godot,'--headless','--path',str(root/'godot'),'-s','tests/'+p.name],env=env,capture_output=True,text=True,timeout=90)
    log=run.stdout+run.stderr;(out/(p.stem+'.txt')).write_text(log)
    ok=run.returncode==0 and 'SCRIPT ERROR' not in log and 'FAIL ' not in log
    results.append({'test':p.name,'exit_code':run.returncode,'passed':ok})
    print(p.name,'PASS' if ok else 'FAIL',flush=True)
(out/'summary.json').write_text(json.dumps(results,indent=2))
raise SystemExit(0 if all(r['passed'] for r in results) else 1)
