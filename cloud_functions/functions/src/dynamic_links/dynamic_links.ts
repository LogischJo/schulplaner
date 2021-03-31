import * as request from 'request-promise';
import { DynamicLinksType } from './src/dynamic_links_type';
import { DynamicLinksLengthType } from './src/dynamic_links_length_type';
import { AppInformation } from './src/app_information';
import * as dotenv from 'dotenv';

dotenv.config();
const globalSocialTitle = "Schulplaner App";
const globalSocialDescription = "Organisiere deinen Schulalltag - gemeinsam mit deinen Mitschülern. Auf all deinen Geräten";
const globalSocialImageLink = "https://schulplaner.pro/assets/logo";

const APIKEY = process.env.DYNAMIC_LINKS_API_KEY;

const URI_PREFIX = "https://schulplaner.page.link";
const LINK_PREFIX = "https://schulplaner.web.app/link/";



export class DynamicLinksLogic {
    static async getJoinLink(publicKey: string, name: string): Promise<string | null> {
        const type = DynamicLinksType.JOIN_BY_KEY;
        const title = `Schulplaner: ${name} beitreten`;
        const shortLink: string | null = await this.generateShortLink(`?type=${type}&data=${publicKey}`,
            title,
            globalSocialDescription,
            globalSocialImageLink,
            DynamicLinksLengthType.UNGUESSABLE);

        return shortLink;
    }

    static async getInvitationLink(uid: string): Promise<string | null> {
        const type = DynamicLinksType.REFERRAL_PERSONAL;
        const shortLink: string | null = await this.generateShortLink(`?type=${type}&referredby=${uid}`,
            globalSocialTitle,
            globalSocialDescription,
            globalSocialImageLink,
            DynamicLinksLengthType.SHORT);

        return shortLink;
    }

    private static async generateShortLink(queryParams: string, socialTitle: string, socialDescription: string, socialImageUrl: string, type: DynamicLinksLengthType): Promise<string | null> {
        const options = {
            method: 'POST',
            uri: `https://firebasedynamiclinks.googleapis.com/v1/shortLinks?key=${APIKEY}`,
            body: this.buildDynamicLink(
                queryParams,
                socialTitle,
                socialDescription,
                socialImageUrl,
                type,
            ),

            json: true
        };

        const shortLink: string | null = await request(options)
            .then(function (parsedBody) {
                if (parsedBody != null && parsedBody.shortLink != null)
                    return parsedBody.shortLink;
                else return null;
            }).catch((e) => {
                return null;
            });
        return shortLink;
    }

    private static buildDynamicLink(
        queryParams: string,
        socialTitle: string,
        socialDescription: string,
        socialImageUrl: string,
        suffix: DynamicLinksLengthType
    ) {
        const dynamicLinkInfo: DynamicLinksInfo = {
            dynamicLinkInfo: {
                domainUriPrefix: URI_PREFIX,
                link: LINK_PREFIX + queryParams,
                androidInfo: {
                    androidPackageName: AppInformation.PACKAGE_NAME,
                    androidMinPackageVersionCode: AppInformation.REQUIRED_PLAY_VERSION,
                },
                iosInfo: {
                    iosBundleId: AppInformation.IOS_BUNDLE_ID,
                    iosIpadBundleId: AppInformation.IOS_BUNDLE_ID,
                    iosAppStoreId: AppInformation.IOS_APP_STORE_ID,
                },
                navigationInfo: {
                    enableForcedRedirect: false,
                },
                analyticsInfo: {

                },
                socialMetaTagInfo: {
                    socialTitle: socialTitle,
                    socialDescription: socialDescription,
                    socialImageLink: socialImageUrl,
                },
            },
            suffix: {
                option: suffix,
            }
        };
        return dynamicLinkInfo;
    }




}


interface DynamicLinksInfo {
    "dynamicLinkInfo": {
        "domainUriPrefix": string,
        "link": string,
        "androidInfo": {
            "androidPackageName": string,
            "androidFallbackLink"?: string,
            "androidMinPackageVersionCode": string
        },
        "iosInfo": {
            "iosBundleId": string,
            "iosFallbackLink"?: string,
            "iosCustomScheme"?: string,
            "iosIpadFallbackLink"?: string,
            "iosIpadBundleId": string,
            "iosAppStoreId": string,
        },
        "navigationInfo"?: {
            "enableForcedRedirect": boolean,
        },
        "analyticsInfo": {
            "googlePlayAnalytics"?: {
                "utmSource": string,
                "utmMedium": string,
                "utmCampaign": string,
                "utmTerm": string,
                "utmContent": string,
                "gclid": string
            },
            "itunesConnectAnalytics"?: {
                "at": string,
                "ct": string,
                "mt": string,
                "pt": string
            },
        },
        "socialMetaTagInfo": {
            "socialTitle": string,
            "socialDescription": string,
            "socialImageLink": string
        }
    },
    "suffix": {
        "option": DynamicLinksLengthType
    }
}


