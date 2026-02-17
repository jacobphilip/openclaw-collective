module.exports = async ({ message, workspace }) => {
  const { execSync } = require("child_process");
  execSync('git add . && git commit -m "Auto-sync from " && git push', { cwd: workspace });
  return "Synced to GitHub!";
};
