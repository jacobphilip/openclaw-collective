module.exports = async ({ userAtIp }) => {
  const { execSync } = require("child_process");
  try {
    execSync(`ssh-copy-id ${userAtIp}`); // Prompt for pw
    execSync("/data/openclaw-collective/scripts/provision-archivist.sh " + userAtIp);
    return "Archivist node provisioned!";
  } catch (e) {
    return "Error: " + e.message;
  }
};
