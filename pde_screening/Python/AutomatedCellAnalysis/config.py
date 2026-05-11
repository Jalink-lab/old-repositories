"""
Functions to read and write to config.ini
Used for local variables like root-paths, and if someone is supreme
"""
import json
import sys
from pathlib import Path


class Config:
    """
    Config object with some simple read/write operations.
    Example:
        from AutomatedCellAnalysis.config import Config
        cfg = Config()
        myPath = cfg.readorwrite('myPath','c:\\')
        // If myPath exists in the config file it is returned, if not it is written
        // to the config file and 'c:\\' is returned
        myPath = cfg.read('myPath', default='c:\\')
        // If myPath exists in the config file it is returned, if not 'c:\\' is returned
    """

    def __init__(self, cfg_path=None):
        if cfg_path is None:
            cfg_path = Path(Path.home(), 'jalink_pde_config.ini')
        self.cfg_file = cfg_path
        if not self.cfg_file.exists():
            self.clear()

    def read(self, name, **kwargs):
        """
        Read the value corresponding to a name
        """
        z = json.loads(self.cfg_file.read_text())
        return z.get(name, kwargs.get('default', None))

    def readorwrite(self, name, default):
        """
        Tries to read the config value.
        If it cannot find it, it returns the default value and adds that value to the config file.
        """
        res = self.read(name, default=None)
        if res is None:
            self.write(name, default)
            return default
        else:
            return res

    def clearname(self, name):
        """
        Clear a name from the config file
        """
        z = json.loads(self.cfg_file.read_text())
        if name in z.keys():
            value = z.pop(name)
            self.cfg_file.write_text(json.dumps(z))
            return value
        else:
            return None

    def list(self):
        """
        List all names in the config file
        """
        z = json.loads(self.cfg_file.read_text())
        return z.keys()

    def write(self, name, value):
        """
        Write a name-value pair to a config file
        """
        if self.cfg_file.exists():
            z = json.loads(self.cfg_file.read_text())
            z.update({name: value})
        else:
            z = {name: value}
        self.cfg_file.write_text(json.dumps(z))

    def clear(self):
        """
        Clear the entire config file
        """
        if sys.version_info.major >= 3 and sys.version_info.minor >= 8:
            self.cfg_file.unlink(missing_ok=True)
        else:
            if self.cfg_file.exists():
                self.cfg_file.unlink()
        self.cfg_file.write_text('{}')
