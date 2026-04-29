# 🐙 CLUSTER CORE: GIT GUIDE

Use these commands to sync your work with GitHub.

## 🚀 The Initial Setup
Only run these if you are setting up the repository for the first time.

1. **Link the Remote**:
   `git remote add origin https://github.com/antonretro/clustercore.git`

2. **The First Push**:
   `git push -u origin master`

## 🔄 Daily Workflow (Pushing Updates)
Run these whenever you've made changes and want to save them to GitHub.

1. **Stage Changes**: 
   `git add .`  
   *(This tells Git to track all your new work.)*

2. **Commit**: 
   `git commit -m "Describe what you changed here"`  
   *(This takes a "snapshot" of your project.)*

3. **Push**: 
   `git push`  
   *(This sends your snapshot up to the cloud!)*

## 💡 Pro Tips
- **Check Status**: Run `git status` to see which files you've modified but haven't committed yet.
- **Mistake?**: Use `git checkout .` to undo your local changes and revert to the last saved commit.
