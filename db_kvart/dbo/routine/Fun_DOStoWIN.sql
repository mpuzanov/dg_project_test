CREATE   FUNCTION [dbo].[Fun_DOStoWIN](
    @DOSstr VARCHAR(500)
)
    RETURNS VARCHAR(500)
AS
BEGIN
    /*
    Используйте лучше
    select [dbo].[Fun_ChangeCodePageStr]('Привет','DOS')
    */
    DECLARE @i INT
        ,@DOS INT
        ,@WIN INT
        ,@str VARCHAR(500)
    SET @i = 1
    SET @str = ''
    WHILE @i <= LEN(@DOSstr)
        BEGIN
            SET @DOS = ASCII(SUBSTRING(@DOSstr, @i, 1))

            SET @WIN = CASE
                           WHEN @DOS >= 0 AND @DOS <= 32 THEN 32
                           WHEN @DOS >= 33 AND @DOS <= 127 THEN 127
                           WHEN @DOS = 128 THEN 192
                           WHEN @DOS = 129 THEN 193
                           WHEN @DOS = 130 THEN 194
                           WHEN @DOS = 131 THEN 195
                           WHEN @DOS = 132 THEN 196
                           WHEN @DOS = 133 THEN 197
                           WHEN @DOS = 134 THEN 198
                           WHEN @DOS = 135 THEN 199
                           WHEN @DOS = 136 THEN 200
                           WHEN @DOS = 137 THEN 201
                           WHEN @DOS = 138 THEN 202
                           WHEN @DOS = 139 THEN 203
                           WHEN @DOS = 140 THEN 204
                           WHEN @DOS = 141 THEN 205
                           WHEN @DOS = 142 THEN 206
                           WHEN @DOS = 143 THEN 207
                           WHEN @DOS = 144 THEN 208
                           WHEN @DOS = 145 THEN 209
                           WHEN @DOS = 146 THEN 210
                           WHEN @DOS = 147 THEN 211
                           WHEN @DOS = 148 THEN 212
                           WHEN @DOS = 149 THEN 213
                           WHEN @DOS = 150 THEN 214
                           WHEN @DOS = 151 THEN 215
                           WHEN @DOS = 152 THEN 216
                           WHEN @DOS = 153 THEN 217
                           WHEN @DOS = 154 THEN 218
                           WHEN @DOS = 155 THEN 219
                           WHEN @DOS = 156 THEN 220
                           WHEN @DOS = 157 THEN 221
                           WHEN @DOS = 158 THEN 222
                           WHEN @DOS = 159 THEN 223
                           WHEN @DOS = 160 THEN 224
                           WHEN @DOS = 161 THEN 225
                           WHEN @DOS = 162 THEN 226
                           WHEN @DOS = 163 THEN 227
                           WHEN @DOS = 164 THEN 228
                           WHEN @DOS = 165 THEN 229
                           WHEN @DOS = 166 THEN 230
                           WHEN @DOS = 167 THEN 231
                           WHEN @DOS = 168 THEN 232
                           WHEN @DOS = 169 THEN 233
                           WHEN @DOS = 170 THEN 234
                           WHEN @DOS = 171 THEN 235
                           WHEN @DOS = 172 THEN 236
                           WHEN @DOS = 173 THEN 237
                           WHEN @DOS = 174 THEN 238
                           WHEN @DOS = 175 THEN 239
                           WHEN @DOS >= 176 AND @DOS <= 223 THEN 32
                           WHEN @DOS = 224 THEN 240
                           WHEN @DOS = 225 THEN 241
                           WHEN @DOS = 226 THEN 242
                           WHEN @DOS = 227 THEN 243
                           WHEN @DOS = 228 THEN 244
                           WHEN @DOS = 229 THEN 245
                           WHEN @DOS = 230 THEN 246
                           WHEN @DOS = 231 THEN 247
                           WHEN @DOS = 232 THEN 248
                           WHEN @DOS = 233 THEN 249
                           WHEN @DOS = 234 THEN 250
                           WHEN @DOS = 235 THEN 251
                           WHEN @DOS = 236 THEN 252
                           WHEN @DOS = 237 THEN 253
                           WHEN @DOS = 238 THEN 254
                           WHEN @DOS = 239 THEN 255
                           WHEN @DOS = 240 THEN 168
                           WHEN @DOS = 241 THEN 184
                           WHEN @DOS = 242 THEN 178
                           WHEN @DOS = 243 THEN 179
                           WHEN @DOS = 244 THEN 32
                           WHEN @DOS = 245 THEN 32
                           WHEN @DOS = 246 THEN 175
                           WHEN @DOS = 247 THEN 191
                           WHEN @DOS = 248 THEN 170
                           WHEN @DOS = 249 THEN 186
                           WHEN @DOS = 250 THEN 32
                           WHEN @DOS = 251 THEN 177
                           WHEN @DOS = 252 THEN 185
                           WHEN @DOS = 253 THEN 32
                           WHEN @DOS = 254 THEN 32
                           WHEN @DOS = 255 THEN 32
                END

            SET @i = @i + 1
            SET @str = @str + CHAR(@WIN)
        END

RETURN @str

END
go

