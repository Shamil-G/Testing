from typing import List, Any
import os.path
import config as cfg


class I18N:
    file_names: List[Any] = []
    files: List[Any] = []
    objects: List[Any] = []

    def get_resource(self, lang, resource_name):
        file_object = ''
        return_value = ''
        file_name = 'i18n.' + lang
        if cfg.os == 'unix':
            file_name = 'i18nu.' + lang
        n_objects = 0
        if cfg.debug_level > 4:
            print("1. I18N. Lang:"+lang+", resource_name: "+resource_name)
        for f_name in self.file_names:
            if cfg.debug_level > 4:
                print("2. I18N. For Files. file_name:" + file_name+str(f_name))
            if f_name == file_name:
                if cfg.debug_level > 4:
                    print("2. I18N. Success file_name:" + file_name)
                file_object = self.objects[n_objects]
                break
            n_objects = n_objects + 1

        if cfg.debug_level > 4:
            print("2. I18N. For Files. n_objects:" + str(n_objects))

        if file_object == '' and os.path.exists(file_name):
            file = open(file_name, "r")
            if cfg.debug_level > 4:
                print("3. I18N. For Files. file_name:" + file_name)
            if file is not None:
                if cfg.debug_level > 4:
                    print("3. I18N. Append File_name:" + file_name)
                self.file_names.append(file_name)
                if cfg.debug_level > 4:
                    print("3. I18N. Append File description:" + file_name)
                self.files.append(file)
                file_object = file.read()
                if cfg.debug_level > 4:
                    print("3. I18N. Append file_object:" + file_object)
                self.objects.append(file_object)

        if file_object != '':
            if cfg.debug_level > 4:
                print("4. I18N. File_object:" + file_object)
            for line in file_object.splitlines():
                if cfg.debug_level > 4:
                    print("4. I18N. line:" + line)
                if resource_name in line:
                    if cfg.debug_level > 4:
                        print("4. I18N. Success line:" + line)
                    return_value = line.split('=', 1)[1]
                    if cfg.debug_level > 4:
                        print("4. I18N. Success return_value:" + return_value)
                    break
        if cfg.debug_level > 4:
            print("5. I18N. return_value:" + return_value)
        if return_value == '':
            return_value = resource_name
        return return_value

    def close(self):
        if cfg.debug_level > 4:
            print("5. I18N. close")
        for file in self.files:
            file.close()
        self.file_names.clear()
        self.files.clear()
        self.objects.clear()
